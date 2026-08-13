using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Chats;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize(Roles = "Seller")]
[Route("api/seller/chats")]
public class SellerChatsController(ShopyDbContext dbContext, IChatService chatService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ChatRoomDto>>> GetRooms()
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var rooms = await dbContext.ChatRooms
            .Where(r => r.StoreId == storeId)
            .Include(r => r.Store)
            .Include(r => r.BuyerUser)
            .OrderByDescending(r => r.LastMessageAt ?? r.CreatedAt)
            .ToListAsync();

        return Ok(rooms.Select(r => ChatsController.ToDto(r, isBuyerView: false)).ToList());
    }

    [HttpGet("by-buyer/{buyerUserId:guid}")]
    public async Task<ActionResult<ChatRoomDto>> GetRoomByBuyer(Guid buyerUserId)
    {
        var storeId = await GetMyStoreIdAsync();
        var room = await dbContext.ChatRooms
            .Include(r => r.Store)
            .Include(r => r.BuyerUser)
            .SingleOrDefaultAsync(r => r.StoreId == storeId && r.BuyerUserId == buyerUserId);
        if (room is null)
        {
            return NotFound(new { message = "Pembeli ini belum pernah memulai percakapan." });
        }

        return Ok(ChatsController.ToDto(room, isBuyerView: false));
    }

    [HttpGet("{roomId:guid}/messages")]
    public async Task<ActionResult<IReadOnlyList<ChatMessageDto>>> GetMessages(
        Guid roomId, [FromQuery] DateTime? before, [FromQuery] int pageSize = 30)
    {
        var storeId = await GetMyStoreIdAsync();
        var room = await dbContext.ChatRooms.SingleOrDefaultAsync(r => r.Id == roomId && r.StoreId == storeId);
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

        return Ok(messages.Select(m => ChatsController.ToMessageDto(m, ChatSenderType.Seller)).ToList());
    }

    [HttpPost("{roomId:guid}/messages")]
    public async Task<ActionResult<ChatMessageDto>> SendMessage(Guid roomId, SendChatMessageRequest request)
    {
        var storeId = await GetMyStoreIdAsync();
        var room = await dbContext.ChatRooms.SingleOrDefaultAsync(r => r.Id == roomId && r.StoreId == storeId);
        if (room is null)
        {
            return NotFound(new { message = "Percakapan tidak ditemukan." });
        }

        if (string.IsNullOrWhiteSpace(request.Body) && request.AttachmentUrl is null && request.ProductId is null)
        {
            return BadRequest(new { message = "Pesan tidak boleh kosong." });
        }

        var userId = User.GetUserId();
        var message = await chatService.SendMessageAsync(
            room, ChatSenderType.Seller, userId, request.Body, request.AttachmentUrl, request.ProductId, request.SubOrderId);

        message = await dbContext.ChatMessages
            .Include(m => m.Product)
            .Include(m => m.SubOrder)
            .SingleAsync(m => m.Id == message.Id);
        return Ok(ChatsController.ToMessageDto(message, ChatSenderType.Seller));
    }

    [HttpPost("{roomId:guid}/read")]
    public async Task<IActionResult> MarkRead(Guid roomId)
    {
        var storeId = await GetMyStoreIdAsync();
        var room = await dbContext.ChatRooms.SingleOrDefaultAsync(r => r.Id == roomId && r.StoreId == storeId);
        if (room is null)
        {
            return NotFound(new { message = "Percakapan tidak ditemukan." });
        }

        var now = DateTime.UtcNow;
        var unread = await dbContext.ChatMessages
            .Where(m => m.ChatRoomId == roomId && m.SenderType == ChatSenderType.Buyer && m.ReadAt == null)
            .ToListAsync();
        foreach (var m in unread)
        {
            m.ReadAt = now;
        }

        room.UnreadCountSeller = 0;
        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    private async Task<Guid?> GetMyStoreIdAsync()
    {
        var userId = User.GetUserId();
        return await dbContext.Stores
            .Where(s => s.OwnerUserId == userId)
            .Select(s => (Guid?)s.Id)
            .SingleOrDefaultAsync();
    }
}
