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
[Route("api/seller/statistics")]
public class SellerStatisticsController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<SellerStatisticsDto>> GetStatistics([FromQuery] string period = "7d")
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var days = period switch { "30d" => 30, "90d" => 90, _ => 7 };
        var now = DateTime.UtcNow;
        var periodStart = now.Date.AddDays(-(days - 1));
        var previousStart = periodStart.AddDays(-days);

        var currentOrders = await LoadOrdersAsync(storeId.Value, periodStart, now);
        var previousOrders = await LoadOrdersAsync(storeId.Value, previousStart, periodStart);

        var omzet = currentOrders.Sum(o => o.Total);
        var previousOmzet = previousOrders.Sum(o => o.Total);
        var orderCount = currentOrders.Count;
        var previousOrderCount = previousOrders.Count;
        var productsSold = currentOrders.Sum(o => o.QuantitySold);
        var previousProductsSold = previousOrders.Sum(o => o.QuantitySold);
        var averageOrder = orderCount > 0 ? omzet / orderCount : 0;
        var previousAverageOrder = previousOrderCount > 0 ? previousOmzet / previousOrderCount : 0;

        var dailySeries = Enumerable.Range(0, days)
            .Select(offset => periodStart.AddDays(offset))
            .Select(day => new DailySalesDto(day, currentOrders.Where(o => o.CreatedAt.Date == day).Sum(o => o.Total)))
            .ToList();

        var aggregates = await dbContext.OrderItems
            .Where(oi => oi.SubOrder!.StoreId == storeId
                && oi.SubOrder.CreatedAt >= periodStart && oi.SubOrder.CreatedAt < now
                && oi.SubOrder.Status != SubOrderStatus.Cancelled && oi.SubOrder.Status != SubOrderStatus.Rejected)
            .GroupBy(oi => oi.ProductId)
            .Select(g => new { ProductId = g.Key, QuantitySold = g.Sum(x => x.Quantity), Revenue = g.Sum(x => x.UnitPrice * x.Quantity) })
            .OrderByDescending(x => x.QuantitySold)
            .Take(5)
            .ToListAsync();
        var productIds = aggregates.Select(a => a.ProductId).ToList();
        var products = await dbContext.Products.Where(p => productIds.Contains(p.Id)).ToDictionaryAsync(p => p.Id);
        var topProducts = aggregates.Select(a =>
        {
            products.TryGetValue(a.ProductId, out var product);
            return new TopProductDto(a.ProductId, product?.Name ?? "(produk dihapus)", product?.ImageUrl, a.QuantitySold, a.Revenue);
        }).ToList();

        return Ok(new SellerStatisticsDto(
            periodStart, now,
            new StatisticsMetricDto(omzet, DeltaPercent(omzet, previousOmzet)),
            new StatisticsMetricDto(orderCount, DeltaPercent(orderCount, previousOrderCount)),
            new StatisticsMetricDto(productsSold, DeltaPercent(productsSold, previousProductsSold)),
            new StatisticsMetricDto(averageOrder, DeltaPercent(averageOrder, previousAverageOrder)),
            dailySeries,
            topProducts));
    }

    private async Task<List<SubOrderStatRow>> LoadOrdersAsync(Guid storeId, DateTime start, DateTime end)
    {
        return await dbContext.SubOrders
            .Where(so => so.StoreId == storeId && so.CreatedAt >= start && so.CreatedAt < end
                && so.Status != SubOrderStatus.Cancelled && so.Status != SubOrderStatus.Rejected)
            .Select(so => new SubOrderStatRow(
                so.CreatedAt,
                so.Subtotal + so.ShippingCost - so.VoucherDiscount,
                so.OrderItems.Sum(oi => oi.Quantity)))
            .ToListAsync();
    }

    private record SubOrderStatRow(DateTime CreatedAt, decimal Total, int QuantitySold);

    private static decimal DeltaPercent(decimal current, decimal previous)
    {
        if (previous == 0)
        {
            return current == 0 ? 0 : 100;
        }
        return Math.Round((current - previous) / previous * 100, 1);
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
