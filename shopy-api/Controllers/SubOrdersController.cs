using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Catalog;
using shopy_api.Models.Orders;
using shopy_api.Services;

namespace shopy_api.Controllers;

/// <summary>
/// Pesanan per toko sisi pembeli — riwayat &amp; detail pesanan sekarang dipecah per
/// <see cref="SubOrder"/> (TASKSELLER.md Fase 4), bukan per <see cref="Order"/> gabungan lagi.
/// </summary>
[ApiController]
[Authorize]
[Route("api/orders/sub-orders")]
public class SubOrdersController(
    ShopyDbContext dbContext, INotificationService notificationService, IStoreBalanceService balanceService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PagedResult<SubOrderSummaryDto>>> GetSubOrders(
        [FromQuery] SubOrderStatus? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var userId = User.GetUserId();
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = dbContext.SubOrders.Where(so => so.Order.UserId == userId);
        if (status is not null)
        {
            query = query.Where(so => so.Status == status);
        }
        query = query.OrderByDescending(so => so.CreatedAt);

        var totalCount = await query.CountAsync();
        var subOrders = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Include(so => so.Store)
            .Include(so => so.Order)
            .Include(so => so.OrderItems).ThenInclude(oi => oi.Product)
            .ToListAsync();

        return Ok(new PagedResult<SubOrderSummaryDto>(subOrders.Select(ToSummaryDto).ToList(), page, pageSize, totalCount));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<SubOrderDetailDto>> GetSubOrder(Guid id)
    {
        var userId = User.GetUserId();
        var subOrder = await dbContext.SubOrders
            .Include(so => so.Store)
            .Include(so => so.Order)
            .Include(so => so.OrderItems)
            .Include(so => so.StatusHistories)
            .SingleOrDefaultAsync(so => so.Id == id && so.Order.UserId == userId);
        if (subOrder is null)
        {
            return NotFound(new { message = "Pesanan tidak ditemukan." });
        }

        var reviewedProductIds = await GetReviewedProductIdsAsync(userId, subOrder.OrderItems.Select(oi => oi.ProductId));
        return Ok(ToDetailDto(subOrder, reviewedProductIds));
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<ActionResult<SubOrderDetailDto>> UpdateStatus(Guid id, UpdateSubOrderStatusRequest request)
    {
        var userId = User.GetUserId();
        var subOrder = await dbContext.SubOrders
            .Include(so => so.Store)
            .Include(so => so.Order).ThenInclude(o => o.SubOrders)
            .Include(so => so.OrderItems)
            .Include(so => so.StatusHistories)
            .SingleOrDefaultAsync(so => so.Id == id && so.Order.UserId == userId);
        if (subOrder is null)
        {
            return NotFound(new { message = "Pesanan tidak ditemukan." });
        }

        var isValidTransition = request.Status switch
        {
            SubOrderStatus.Cancelled => subOrder.Status is SubOrderStatus.WaitingPayment or SubOrderStatus.NewOrder,
            SubOrderStatus.Completed => subOrder.Status == SubOrderStatus.Shipped,
            _ => false,
        };
        if (!isValidTransition)
        {
            return BadRequest(new { message = "Perubahan status pesanan tidak diizinkan." });
        }

        var now = DateTime.UtcNow;
        subOrder.Status = request.Status;
        subOrder.UpdatedAt = now;
        if (request.Status == SubOrderStatus.Completed)
        {
            subOrder.CompletedAt = now;
        }
        dbContext.SubOrderStatusHistories.Add(new SubOrderStatusHistory
        {
            Id = Guid.NewGuid(),
            SubOrderId = subOrder.Id,
            Status = request.Status,
            ChangedAt = now,
        });

        subOrder.Order.Status = OrderStatusHelper.Recalculate(subOrder.Order.SubOrders.Select(so => so.Id == subOrder.Id ? request.Status : so.Status));
        subOrder.Order.UpdatedAt = now;

        await dbContext.SaveChangesAsync();

        if (request.Status == SubOrderStatus.Completed)
        {
            await balanceService.SettleAsync(subOrder);
        }
        else if (request.Status == SubOrderStatus.Cancelled)
        {
            await balanceService.ReleasePendingAsync(subOrder);
        }

        await notificationService.NotifySubOrderStatusChangedAsync(subOrder, subOrder.Store);

        var reviewedProductIds = await GetReviewedProductIdsAsync(userId, subOrder.OrderItems.Select(oi => oi.ProductId));
        return Ok(ToDetailDto(subOrder, reviewedProductIds));
    }

    private async Task<List<Guid>> GetReviewedProductIdsAsync(Guid userId, IEnumerable<Guid> productIds)
    {
        var ids = productIds.Distinct().ToList();
        if (ids.Count == 0)
        {
            return [];
        }
        return await dbContext.Reviews
            .Where(r => r.UserId == userId && ids.Contains(r.ProductId))
            .Select(r => r.ProductId)
            .ToListAsync();
    }

    public static SubOrderSummaryDto ToSummaryDto(SubOrder so) => new(
        so.Id, so.SubOrderNumber, so.OrderId, so.Order.OrderNumber, so.StoreId, so.Store.Name, so.Store.LogoUrl,
        so.Status.ToString(), so.Subtotal, so.ShippingCost, so.VoucherDiscount,
        so.Subtotal + so.ShippingCost - so.VoucherDiscount, so.OrderItems.Count,
        so.OrderItems.Take(3).Select(oi => oi.Product.ImageUrl).ToList(), so.CreatedAt);

    public static SubOrderDetailDto ToDetailDto(SubOrder so, IReadOnlyList<Guid> reviewedProductIds) => new(
        so.Id, so.SubOrderNumber, so.OrderId, so.Order.OrderNumber, so.StoreId, so.Store.Name, so.Store.LogoUrl,
        so.Status.ToString(), so.Subtotal, so.ShippingCost, so.VoucherDiscount, so.Subtotal + so.ShippingCost - so.VoucherDiscount,
        so.CourierCode, so.CourierService, so.TrackingNumber,
        new OrderAddressSnapshotDto(
            so.Order.RecipientName, so.Order.PhoneNumber, so.Order.FullAddress, so.Order.City, so.Order.Province, so.Order.PostalCode),
        so.Order.Note,
        so.OrderItems.Select(oi => new OrderItemDto(oi.Id, oi.ProductId, oi.ProductNameSnapshot, oi.UnitPrice, oi.Quantity, oi.Subtotal)).ToList(),
        so.StatusHistories.OrderBy(h => h.ChangedAt).Select(h => new SubOrderStatusHistoryDto(h.Status.ToString(), h.Note, h.ChangedAt)).ToList(),
        so.CreatedAt, reviewedProductIds);
}
