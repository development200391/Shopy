using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;

namespace shopy_api.Services;

/// <summary>
/// Auto-reject pesanan yang tidak direspon seller dalam batas waktu (`AutoCancelAt`), dan
/// auto-complete pesanan yang sudah dikirim tapi tidak dikonfirmasi pembeli dalam
/// `Platform:AutoCompleteDays` sejak `ShippedAt` (TASKSELLER.md Fase 4).
/// </summary>
public class SubOrderAutoTransitionService(IServiceScopeFactory scopeFactory, IConfiguration configuration) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(5);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);
        do
        {
            try
            {
                await RunOnceAsync(stoppingToken);
            }
            catch (Exception) when (!stoppingToken.IsCancellationRequested)
            {
                // Jangan biarkan satu error mematikan background service selamanya — coba lagi tick berikutnya.
            }
        } while (await timer.WaitForNextTickAsync(stoppingToken));
    }

    private async Task RunOnceAsync(CancellationToken stoppingToken)
    {
        using var scope = scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ShopyDbContext>();
        var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

        var now = DateTime.UtcNow;
        var autoCompleteDays = configuration.GetValue("Platform:AutoCompleteDays", 3);

        var expiredNew = await dbContext.SubOrders
            .Where(so => so.Status == SubOrderStatus.NewOrder && so.AutoCancelAt != null && so.AutoCancelAt <= now)
            .Include(so => so.Store)
            .Include(so => so.Order).ThenInclude(o => o.SubOrders)
            .ToListAsync(stoppingToken);

        foreach (var subOrder in expiredNew)
        {
            subOrder.Status = SubOrderStatus.Rejected;
            subOrder.CancelReason = "Otomatis dibatalkan karena toko tidak merespon dalam batas waktu.";
            subOrder.AutoCancelAt = null;
            subOrder.UpdatedAt = now;
            dbContext.SubOrderStatusHistories.Add(new SubOrderStatusHistory
            {
                Id = Guid.NewGuid(),
                SubOrderId = subOrder.Id,
                Status = SubOrderStatus.Rejected,
                Note = subOrder.CancelReason,
                ChangedAt = now,
            });
            subOrder.Order.Status = OrderStatusHelper.Recalculate(subOrder.Order.SubOrders.Select(so => so.Status));
            subOrder.Order.UpdatedAt = now;
        }

        var completeBefore = now.AddDays(-autoCompleteDays);
        var expiredShipped = await dbContext.SubOrders
            .Where(so => so.Status == SubOrderStatus.Shipped && so.ShippedAt != null && so.ShippedAt <= completeBefore)
            .Include(so => so.Store)
            .Include(so => so.Order).ThenInclude(o => o.SubOrders)
            .ToListAsync(stoppingToken);

        foreach (var subOrder in expiredShipped)
        {
            subOrder.Status = SubOrderStatus.Completed;
            subOrder.CompletedAt = now;
            subOrder.UpdatedAt = now;
            dbContext.SubOrderStatusHistories.Add(new SubOrderStatusHistory
            {
                Id = Guid.NewGuid(),
                SubOrderId = subOrder.Id,
                Status = SubOrderStatus.Completed,
                ChangedAt = now,
            });
            subOrder.Order.Status = OrderStatusHelper.Recalculate(subOrder.Order.SubOrders.Select(so => so.Status));
            subOrder.Order.UpdatedAt = now;
        }

        var changed = expiredNew.Concat(expiredShipped).ToList();
        if (changed.Count == 0)
        {
            return;
        }

        await dbContext.SaveChangesAsync(stoppingToken);
        foreach (var subOrder in changed)
        {
            await notificationService.NotifySubOrderStatusChangedAsync(subOrder, subOrder.Store);
        }
    }
}
