using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;

namespace shopy_api.Services;

public interface IChatService
{
    Task<ChatMessage> SendMessageAsync(
        ChatRoom room,
        ChatSenderType senderType,
        Guid senderUserId,
        string? body,
        string? attachmentUrl,
        Guid? productId,
        Guid? subOrderId);
}

/// <summary>
/// Titik tunggal kirim pesan chat — dipakai identik oleh <c>ChatsController</c> (pembeli) &amp;
/// <c>SellerChatsController</c> (penjual) supaya logika unread/preview/push selalu simetris
/// di kedua arah (TASKSELLER.md Fase 7). Realtime cukup polling + push FCM, bukan SignalR —
/// lihat catatan di plan fase ini.
/// </summary>
public class ChatService(ShopyDbContext dbContext, IPushNotificationService pushService) : IChatService
{
    public async Task<ChatMessage> SendMessageAsync(
        ChatRoom room,
        ChatSenderType senderType,
        Guid senderUserId,
        string? body,
        string? attachmentUrl,
        Guid? productId,
        Guid? subOrderId)
    {
        var now = DateTime.UtcNow;
        var message = new ChatMessage
        {
            Id = Guid.NewGuid(),
            ChatRoomId = room.Id,
            SenderType = senderType,
            SenderUserId = senderUserId,
            Body = body,
            AttachmentUrl = attachmentUrl,
            ProductId = productId,
            SubOrderId = subOrderId,
            CreatedAt = now,
        };
        dbContext.ChatMessages.Add(message);

        room.LastMessageAt = now;
        room.LastMessagePreview = BuildPreview(body, attachmentUrl, productId);
        if (senderType == ChatSenderType.Buyer)
        {
            room.UnreadCountSeller++;
        }
        else
        {
            room.UnreadCountBuyer++;
        }

        await dbContext.SaveChangesAsync();

        var recipientUserId = senderType == ChatSenderType.Buyer
            ? await GetSellerUserIdAsync(room.StoreId)
            : room.BuyerUserId;

        var tokens = await dbContext.DeviceTokens
            .Where(t => t.UserId == recipientUserId)
            .Select(t => t.Token)
            .ToListAsync();
        await pushService.SendAsync(
            tokens,
            "Pesan Baru",
            string.IsNullOrEmpty(room.LastMessagePreview) ? "Kamu dapat pesan baru" : room.LastMessagePreview,
            new Dictionary<string, string> { ["type"] = "chat", ["roomId"] = room.Id.ToString() });

        return message;
    }

    private async Task<Guid> GetSellerUserIdAsync(Guid storeId)
    {
        return await dbContext.Stores.Where(s => s.Id == storeId).Select(s => s.OwnerUserId).SingleAsync();
    }

    private static string BuildPreview(string? body, string? attachmentUrl, Guid? productId)
    {
        if (!string.IsNullOrWhiteSpace(body))
        {
            return body.Length > 120 ? body[..120] : body;
        }
        if (productId is not null)
        {
            return "[Produk]";
        }
        if (attachmentUrl is not null)
        {
            return "[Gambar]";
        }
        return string.Empty;
    }
}
