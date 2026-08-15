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
public class ChatService(ShopyDbContext dbContext, IPushNotificationService pushService, INotificationService notificationService) : IChatService
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

        if (senderType == ChatSenderType.Buyer)
        {
            // Penerima = seller — insert baris Notification (TASKSELLER.md Fase 8) + push
            // ke device token yang terdaftar sebagai app Seller. Beda dari cabang di bawah:
            // sengaja pakai NotificationService supaya muncul di histori Notifikasi seller.
            var store = await dbContext.Stores.SingleAsync(s => s.Id == room.StoreId);
            await notificationService.NotifyNewChatAsync(room, store, room.LastMessagePreview ?? string.Empty);
        }
        else
        {
            // Penerima = buyer — buyer belum punya notification-center untuk chat (Fase 7),
            // jadi push langsung tanpa baris Notification, persis pola lama.
            var tokens = await dbContext.DeviceTokens
                .Where(t => t.UserId == room.BuyerUserId)
                .Select(t => t.Token)
                .ToListAsync();
            await pushService.SendAsync(
                tokens,
                "Pesan Baru",
                string.IsNullOrEmpty(room.LastMessagePreview) ? "Kamu dapat pesan baru" : room.LastMessagePreview,
                new Dictionary<string, string> { ["type"] = "chat", ["roomId"] = room.Id.ToString() });
        }

        return message;
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
