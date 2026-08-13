using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Catalog;
using shopy_api.Models.Orders;
using shopy_api.Models.Sellers;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize(Roles = "Seller")]
[Route("api/seller/orders")]
public class SellerOrdersController(
    ShopyDbContext dbContext, INotificationService notificationService, IStoreBalanceService balanceService) : ControllerBase
{
    private static readonly Dictionary<string, SubOrderStatus> StatusByTab = new()
    {
        ["new"] = SubOrderStatus.NewOrder,
        ["processing"] = SubOrderStatus.Processing,
        ["shipped"] = SubOrderStatus.Shipped,
        ["completed"] = SubOrderStatus.Completed,
    };

    [HttpGet]
    public async Task<ActionResult<PagedResult<SellerSubOrderListItemDto>>> GetOrders(
        [FromQuery] string status = "new", [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        if (!StatusByTab.TryGetValue(status, out var subOrderStatus))
        {
            return BadRequest(new { message = "Status tidak dikenal." });
        }

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = dbContext.SubOrders.Where(so => so.StoreId == storeId && so.Status == subOrderStatus)
            .OrderByDescending(so => so.CreatedAt);

        var totalCount = await query.CountAsync();
        var subOrders = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Include(so => so.Order).ThenInclude(o => o.User)
            .Include(so => so.OrderItems).ThenInclude(oi => oi.Product)
            .ToListAsync();

        var items = subOrders.Select(so => new SellerSubOrderListItemDto(
            so.Id, so.SubOrderNumber, so.Status.ToString(), so.Order.User.FullName, so.OrderItems.Count,
            so.OrderItems.Take(3).Select(oi => oi.Product.ImageUrl).ToList(), so.Subtotal + so.ShippingCost - so.VoucherDiscount,
            so.AutoCancelAt, so.CreatedAt)).ToList();

        return Ok(new PagedResult<SellerSubOrderListItemDto>(items, page, pageSize, totalCount));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<SellerSubOrderDetailDto>> GetOrder(Guid id)
    {
        var storeId = await GetMyStoreIdAsync();
        var subOrder = await dbContext.SubOrders
            .Include(so => so.Order).ThenInclude(o => o.User)
            .Include(so => so.OrderItems)
            .Include(so => so.StatusHistories)
            .SingleOrDefaultAsync(so => so.Id == id && so.StoreId == storeId);
        if (subOrder is null)
        {
            return NotFound(new { message = "Pesanan tidak ditemukan." });
        }

        var orderCount = await dbContext.SubOrders
            .CountAsync(so => so.StoreId == storeId && so.Order.UserId == subOrder.Order.UserId);

        return Ok(await ToDetailDtoAsync(subOrder, orderCount));
    }

    [HttpPost("{id:guid}/accept")]
    public async Task<ActionResult<SellerSubOrderDetailDto>> Accept(Guid id)
    {
        var subOrder = await LoadForTransitionAsync(id);
        if (subOrder is null)
        {
            return NotFound(new { message = "Pesanan tidak ditemukan." });
        }

        if (subOrder.Status != SubOrderStatus.NewOrder)
        {
            return BadRequest(new { message = "Pesanan ini tidak bisa diproses dari status saat ini." });
        }

        var now = DateTime.UtcNow;
        foreach (var item in subOrder.OrderItems)
        {
            item.Product.Stock = Math.Max(0, item.Product.Stock - item.Quantity);
        }

        subOrder.Status = SubOrderStatus.Processing;
        subOrder.UpdatedAt = now;
        subOrder.AutoCancelAt = null;
        await TransitionAsync(subOrder, null, now);

        return await GetOrder(id);
    }

    [HttpPost("{id:guid}/reject")]
    public async Task<ActionResult<SellerSubOrderDetailDto>> Reject(Guid id, RejectSubOrderRequest request)
    {
        var subOrder = await LoadForTransitionAsync(id);
        if (subOrder is null)
        {
            return NotFound(new { message = "Pesanan tidak ditemukan." });
        }

        if (subOrder.Status != SubOrderStatus.NewOrder)
        {
            return BadRequest(new { message = "Pesanan ini tidak bisa ditolak dari status saat ini." });
        }

        var now = DateTime.UtcNow;
        subOrder.Status = SubOrderStatus.Rejected;
        subOrder.CancelReason = request.Reason;
        subOrder.UpdatedAt = now;
        subOrder.AutoCancelAt = null;
        await TransitionAsync(subOrder, request.Reason, now);
        // Sub-order ini sudah pernah Settled (cuma bisa reject dari NewOrder), jadi ada dana
        // tertahan yang perlu dilepas balik.
        await balanceService.ReleasePendingAsync(subOrder);

        return await GetOrder(id);
    }

    [HttpPost("{id:guid}/ship")]
    public async Task<ActionResult<SellerSubOrderDetailDto>> Ship(Guid id, ShipSubOrderRequest request)
    {
        var subOrder = await LoadForTransitionAsync(id);
        if (subOrder is null)
        {
            return NotFound(new { message = "Pesanan tidak ditemukan." });
        }

        if (subOrder.Status != SubOrderStatus.Processing)
        {
            return BadRequest(new { message = "Pesanan ini belum siap dikirim." });
        }

        var now = DateTime.UtcNow;
        subOrder.Status = SubOrderStatus.Shipped;
        subOrder.CourierCode = request.CourierCode;
        subOrder.CourierService = request.CourierService;
        subOrder.TrackingNumber = request.TrackingNumber;
        subOrder.ProofPhotoUrl = request.ProofPhotoUrl;
        subOrder.ShippedAt = now;
        subOrder.UpdatedAt = now;
        await TransitionAsync(subOrder, null, now);

        return await GetOrder(id);
    }

    private async Task<SubOrder?> LoadForTransitionAsync(Guid id)
    {
        var storeId = await GetMyStoreIdAsync();
        return await dbContext.SubOrders
            .Include(so => so.Store)
            .Include(so => so.Order).ThenInclude(o => o.SubOrders)
            .Include(so => so.OrderItems).ThenInclude(oi => oi.Product)
            .SingleOrDefaultAsync(so => so.Id == id && so.StoreId == storeId);
    }

    private async Task TransitionAsync(SubOrder subOrder, string? note, DateTime now)
    {
        dbContext.SubOrderStatusHistories.Add(new SubOrderStatusHistory
        {
            Id = Guid.NewGuid(),
            SubOrderId = subOrder.Id,
            Status = subOrder.Status,
            Note = note,
            ChangedAt = now,
        });
        subOrder.Order.Status = OrderStatusHelper.Recalculate(subOrder.Order.SubOrders.Select(so => so.Status));
        subOrder.Order.UpdatedAt = now;

        await dbContext.SaveChangesAsync();
        await notificationService.NotifySubOrderStatusChangedAsync(subOrder, subOrder.Store);
    }

    private async Task<Guid?> GetMyStoreIdAsync()
    {
        var userId = User.GetUserId();
        return await dbContext.Stores
            .Where(s => s.OwnerUserId == userId)
            .Select(s => (Guid?)s.Id)
            .SingleOrDefaultAsync();
    }

    private static Task<SellerSubOrderDetailDto> ToDetailDtoAsync(SubOrder so, int orderCount) => Task.FromResult(new SellerSubOrderDetailDto(
        so.Id, so.SubOrderNumber, so.Status.ToString(),
        new BuyerInfoDto(so.Order.UserId, so.Order.User.FullName, so.Order.User.CreatedAt.Year, orderCount),
        new OrderAddressSnapshotDto(
            so.Order.RecipientName, so.Order.PhoneNumber, so.Order.FullAddress, so.Order.City, so.Order.Province, so.Order.PostalCode),
        so.OrderItems.Select(oi => new OrderItemDto(oi.Id, oi.ProductId, oi.ProductNameSnapshot, oi.UnitPrice, oi.Quantity, oi.Subtotal)).ToList(),
        so.Subtotal, so.ShippingCost, so.VoucherDiscount, so.CommissionAmount, so.SellerEarning,
        so.Subtotal + so.ShippingCost - so.VoucherDiscount,
        so.CourierCode, so.CourierService, so.TrackingNumber, so.ProofPhotoUrl,
        so.Order.Note, so.CancelReason, so.AutoCancelAt,
        so.StatusHistories.OrderBy(h => h.ChangedAt).Select(h => new SubOrderStatusHistoryDto(h.Status.ToString(), h.Note, h.ChangedAt)).ToList(),
        so.CreatedAt));
}
