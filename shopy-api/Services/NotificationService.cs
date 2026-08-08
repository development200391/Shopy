using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;

namespace shopy_api.Services;

public class NotificationService(ShopyDbContext dbContext, IPushNotificationService pushService) : INotificationService
{
    public async Task NotifyOrderStatusChangedAsync(Order order)
    {
        var statusLabel = order.Status switch
        {
            OrderStatus.Pending => "menunggu konfirmasi",
            OrderStatus.Processing => "sedang diproses",
            OrderStatus.Shipped => "sedang dikirim",
            OrderStatus.Completed => "selesai",
            OrderStatus.Cancelled => "dibatalkan",
            _ => order.Status.ToString(),
        };

        const string title = "Status Pesanan Diperbarui";
        var body = $"Pesanan #{order.OrderNumber} {statusLabel}.";

        dbContext.Notifications.Add(new Notification
        {
            Id = Guid.NewGuid(),
            UserId = order.UserId,
            Type = NotificationType.OrderStatus,
            Title = title,
            Body = body,
            OrderId = order.Id,
            CreatedAt = DateTime.UtcNow,
        });
        await dbContext.SaveChangesAsync();

        var tokens = await dbContext.DeviceTokens.Where(t => t.UserId == order.UserId).Select(t => t.Token).ToListAsync();
        await pushService.SendAsync(
            tokens, title, body,
            new Dictionary<string, string> { ["type"] = "order_status", ["orderId"] = order.Id.ToString() });
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
