using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Sellers;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize(Roles = "Seller")]
[Route("api/seller/dashboard")]
public class SellerDashboardController(ShopyDbContext dbContext) : ControllerBase
{
    private const int LowStockThreshold = 10;

    [HttpGet]
    public async Task<ActionResult<SellerDashboardDto>> GetDashboard()
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var balance = await dbContext.StoreBalances.SingleOrDefaultAsync(b => b.StoreId == storeId);

        var todayStart = DateTime.UtcNow.Date;
        var todayOrders = await dbContext.SubOrders
            .Where(so => so.StoreId == storeId && so.CreatedAt >= todayStart
                && so.Status != SubOrderStatus.Cancelled && so.Status != SubOrderStatus.Rejected)
            .Include(so => so.OrderItems)
            .ToListAsync();
        var productsSoldToday = todayOrders.Sum(so => so.OrderItems.Sum(oi => oi.Quantity));
        var incomeToday = todayOrders.Sum(so => so.SellerEarning);

        // Belum ada tabel log kunjungan per-hari, jadi ini kumulatif (bukan "hari ini")
        // — deviasi yang didokumentasikan di TASKSELLER.md Fase 8.
        var storeVisitors = await dbContext.Products.Where(p => p.StoreId == storeId).SumAsync(p => p.ViewCount);

        var newOrders = await dbContext.SubOrders.CountAsync(so => so.StoreId == storeId && so.Status == SubOrderStatus.NewOrder);
        // Tidak ada status "ReadyToShip" terpisah di skema — "siap dikirim" dipetakan ke Processing.
        var readyToShip = await dbContext.SubOrders.CountAsync(so => so.StoreId == storeId && so.Status == SubOrderStatus.Processing);
        var lowStockCount = await dbContext.Products.CountAsync(p => p.StoreId == storeId && p.IsActive && p.Stock <= LowStockThreshold);
        var unrepliedReviews = await dbContext.Reviews.CountAsync(r => r.StoreId == storeId && r.SellerReply == null);

        var sevenDaysAgo = todayStart.AddDays(-6);
        var recentOrders = await dbContext.SubOrders
            .Where(so => so.StoreId == storeId && so.CreatedAt >= sevenDaysAgo
                && so.Status != SubOrderStatus.Cancelled && so.Status != SubOrderStatus.Rejected)
            .Select(so => new { so.CreatedAt, Total = so.Subtotal + so.ShippingCost - so.VoucherDiscount })
            .ToListAsync();
        var sales7Days = Enumerable.Range(0, 7)
            .Select(offset => sevenDaysAgo.AddDays(offset))
            .Select(day => new DailySalesDto(day, recentOrders.Where(o => o.CreatedAt.Date == day).Sum(o => o.Total)))
            .ToList();

        return Ok(new SellerDashboardDto(
            balance?.AvailableBalance ?? 0,
            balance?.PendingBalance ?? 0,
            newOrders,
            productsSoldToday,
            storeVisitors,
            incomeToday,
            new NeedsFollowUpDto(newOrders, readyToShip, lowStockCount, unrepliedReviews),
            sales7Days));
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
