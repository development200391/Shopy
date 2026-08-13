using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;

namespace shopy_api.Services;

public class NotificationService(ShopyDbContext dbContext, IPushNotificationService pushService) : INotificationService
{
    /// <remarks><paramref name="subOrder"/>.Order harus sudah di-<c>Include</c> oleh pemanggil.</remarks>
    public async Task NotifySubOrderStatusChangedAsync(SubOrder subOrder, Store store)
    {
        var statusLabel = subOrder.Status switch
        {
            SubOrderStatus.WaitingPayment => "menunggu pembayaran",
            SubOrderStatus.NewOrder => "menunggu konfirmasi toko",
            SubOrderStatus.Processing => "sedang diproses",
            SubOrderStatus.Shipped => "sedang dikirim",
            SubOrderStatus.Completed => "selesai",
            SubOrderStatus.Cancelled => "dibatalkan",
            SubOrderStatus.Rejected => "ditolak penjual",
            _ => subOrder.Status.ToString(),
        };

        const string title = "Status Pesanan Diperbarui";
        var body = $"Pesanan #{subOrder.SubOrderNumber} dari {store.Name} {statusLabel}.";

        dbContext.Notifications.Add(new Notification
        {
            Id = Guid.NewGuid(),
            UserId = subOrder.Order.UserId,
            Type = NotificationType.OrderStatus,
            Title = title,
            Body = body,
            OrderId = subOrder.OrderId,
            CreatedAt = DateTime.UtcNow,
        });
        await dbContext.SaveChangesAsync();

        var tokens = await dbContext.DeviceTokens.Where(t => t.UserId == subOrder.Order.UserId).Select(t => t.Token).ToListAsync();
        await pushService.SendAsync(
            tokens, title, body,
            new Dictionary<string, string> { ["type"] = "order_status", ["orderId"] = subOrder.OrderId.ToString() });
    }

    public async Task<int> BroadcastPromoAsync(string title, string body)
    {
        var userIds = await dbContext.Users.Select(u => u.Id).ToListAsync();
        var now = DateTime.UtcNow;

        foreach (var userId in userIds)
        {
            dbContext.Notifications.Add(new Notification
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Type = NotificationType.Promo,
                Title = title,
                Body = body,
                CreatedAt = now,
            });
        }
        await dbContext.SaveChangesAsync();

        var tokens = await dbContext.DeviceTokens.Select(t => t.Token).ToListAsync();
        // FCM multicast maksimal 500 token per panggilan.
        foreach (var batch in tokens.Chunk(500))
        {
            await pushService.SendAsync(batch, title, body, new Dictionary<string, string> { ["type"] = "promo" });
        }

        return userIds.Count;
    }
}
