using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Chats;
using shopy_api.Services;

namespace shopy_api.Controllers;

/// <summary>Sisi pembeli — buka/pakai percakapan dengan sebuah toko.</summary>
[ApiController]
[Authorize]
[Route("api/chats")]
public class ChatsController(ShopyDbContext dbContext, IChatService chatService) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<ChatRoomDto>> OpenRoom(OpenChatRoomRequest request)
    {
        var userId = User.GetUserId();

        var store = await dbContext.Stores.SingleOrDefaultAsync(s => s.Id == request.StoreId);
        if (store is null)
        {
            return NotFound(new { message = "Toko tidak ditemukan." });
        }

        var room = await dbContext.ChatRooms
            .Include(r => r.Store)
            .Include(r => r.BuyerUser)
            .SingleOrDefaultAsync(r => r.StoreId == request.StoreId && r.BuyerUserId == userId);

        if (room is null)
        {
            room = new ChatRoom
            {
                Id = Guid.NewGuid(),
                StoreId = request.StoreId,
                BuyerUserId = userId,
                CreatedAt = DateTime.UtcNow,
            };
            dbContext.ChatRooms.Add(room);
            await dbContext.SaveChangesAsync();
            room.Store = store;
            room.BuyerUser = await dbContext.Users.SingleAsync(u => u.Id == userId);
        }

        return Ok(ToDto(room, isBuyerView: true));
    }

    [HttpGet("{roomId:guid}/messages")]
    public async Task<ActionResult<IReadOnlyList<ChatMessageDto>>> GetMessages(
        Guid roomId, [FromQuery] DateTime? before, [FromQuery] int pageSize = 30)
    {
        var userId = User.GetUserId();
        var room = await dbContext.ChatRooms.SingleOrDefaultAsync(r => r.Id == roomId && r.BuyerUserId == userId);
        if (room is null)
        {
            return NotFound(new { message = "Percakapan tidak ditemukan." });
        }

        pageSize = Math.Clamp(pageSize, 1, 100);
        var query = dbContext.ChatMessages.Where(m => m.ChatRoomId == roomId);
        if (before is not null)
        {
            query = query.Where(m => m.CreatedAt < before);
        }

        var messages = await query
            .OrderByDescending(m => m.CreatedAt)
            .Take(pageSize)
            .Include(m => m.Product)
            .Include(m => m.SubOrder)
            .ToListAsync();
        messages.Reverse();

        return Ok(messages.Select(m => ToMessageDto(m, ChatSenderType.Buyer)).ToList());
    }

    [HttpPost("{roomId:guid}/messages")]
    public async Task<ActionResult<ChatMessageDto>> SendMessage(Guid roomId, SendChatMessageRequest request)
    {
        var userId = User.GetUserId();
        var room = await dbContext.ChatRooms.SingleOrDefaultAsync(r => r.Id == roomId && r.BuyerUserId == userId);
        if (room is null)
        {
            return NotFound(new { message = "Percakapan tidak ditemukan." });
        }

        if (string.IsNullOrWhiteSpace(request.Body) && request.AttachmentUrl is null && request.ProductId is null)
        {
            return BadRequest(new { message = "Pesan tidak boleh kosong." });
        }

        var message = await chatService.SendMessageAsync(
            room, ChatSenderType.Buyer, userId, request.Body, request.AttachmentUrl, request.ProductId, request.SubOrderId);

        message = await dbContext.ChatMessages
            .Include(m => m.Product)
            .Include(m => m.SubOrder)
            .SingleAsync(m => m.Id == message.Id);
        return Ok(ToMessageDto(message, ChatSenderType.Buyer));
    }

    [HttpPost("{roomId:guid}/read")]
    public async Task<IActionResult> MarkRead(Guid roomId)
    {
        var userId = User.GetUserId();
        var room = await dbContext.ChatRooms.SingleOrDefaultAsync(r => r.Id == roomId && r.BuyerUserId == userId);
        if (room is null)
        {
            return NotFound(new { message = "Percakapan tidak ditemukan." });
        }

        var now = DateTime.UtcNow;
        var unread = await dbContext.ChatMessages
            .Where(m => m.ChatRoomId == roomId && m.SenderType == ChatSenderType.Seller && m.ReadAt == null)
            .ToListAsync();
        foreach (var m in unread)
        {
            m.ReadAt = now;
        }

        room.UnreadCountBuyer = 0;
        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    public static ChatRoomDto ToDto(ChatRoom room, bool isBuyerView) => new(
        room.Id, room.StoreId, room.Store.Name, room.Store.LogoUrl,
        room.BuyerUserId, room.BuyerUser.FullName, room.BuyerUser.AvatarUrl,
        room.LastMessagePreview, room.LastMessageAt,
        isBuyerView ? room.UnreadCountBuyer : room.UnreadCountSeller,
        room.CreatedAt);

    public static ChatMessageDto ToMessageDto(ChatMessage m, ChatSenderType viewer) => new(
        m.Id, m.SenderType.ToString(), m.SenderType == viewer, m.Body, m.AttachmentUrl,
        m.Product is null ? null : new ChatProductAttachmentDto(m.Product.Id, m.Product.Name, m.Product.ImageUrl, m.Product.Price, m.Product.Stock),
        m.SubOrder?.SubOrderNumber, m.ReadAt, m.CreatedAt);
}
