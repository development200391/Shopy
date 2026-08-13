using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Catalog;
using shopy_api.Models.Orders;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize]
[Route("api/orders")]
public class OrdersController(ShopyDbContext dbContext, IConfiguration configuration) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PagedResult<OrderSummaryDto>>> GetOrders(
        [FromQuery] OrderStatus? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var userId = User.GetUserId();
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = dbContext.Orders.Where(o => o.UserId == userId);
        if (status is not null)
        {
            query = query.Where(o => o.Status == status);
        }
        query = query.OrderByDescending(o => o.CreatedAt);

        var totalCount = await query.CountAsync();
        var orders = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .ToListAsync();

        var items = orders.Select(o => new OrderSummaryDto(
            o.Id, o.OrderNumber, o.Status.ToString(), o.TotalAmount, o.OrderItems.Count,
            o.OrderItems.Take(3).Select(oi => oi.Product.ImageUrl).ToList(), o.CreatedAt)).ToList();

        return Ok(new PagedResult<OrderSummaryDto>(items, page, pageSize, totalCount));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<OrderDetailDto>> GetOrder(Guid id)
    {
        var userId = User.GetUserId();
        var order = await dbContext.Orders
            .Include(o => o.SubOrders).ThenInclude(so => so.Store)
            .Include(o => o.SubOrders).ThenInclude(so => so.OrderItems).ThenInclude(oi => oi.Product)
            .SingleOrDefaultAsync(o => o.Id == id && o.UserId == userId);
        if (order is null)
        {
            return NotFound(new { message = "Pesanan tidak ditemukan." });
        }

        return Ok(ToDetailDto(order));
    }

    [HttpPost]
    public async Task<ActionResult<OrderDetailDto>> Checkout(CheckoutRequest request)
    {
        if (request.CartItemIds.Count == 0)
        {
            return BadRequest(new { message = "Pilih minimal 1 produk untuk checkout." });
        }

        var userId = User.GetUserId();

        var address = await dbContext.Addresses.SingleOrDefaultAsync(a => a.Id == request.AddressId && a.UserId == userId);
        if (address is null)
        {
            return BadRequest(new { message = "Alamat pengiriman tidak valid." });
        }

        var cart = await dbContext.Carts.SingleOrDefaultAsync(c => c.UserId == userId);
        var cartItems = cart is null
            ? []
            : await dbContext.CartItems
                .Include(ci => ci.Product)
                .Where(ci => ci.CartId == cart.Id && request.CartItemIds.Contains(ci.Id))
                .ToListAsync();

        if (cartItems.Count != request.CartItemIds.Count)
        {
            return BadRequest(new { message = "Sebagian produk di keranjang tidak ditemukan." });
        }

        foreach (var item in cartItems)
        {
            if (item.Quantity > item.Product.Stock)
            {
                return BadRequest(new { message = $"Stok {item.Product.Name} tidak mencukupi." });
            }
        }

        var commissionPercent = configuration.GetValue("Platform:CommissionPercent", 2m);
        var courier = Couriers.Default;
        var now = DateTime.UtcNow;
        var orderNumber = await GenerateOrderNumberAsync();

        // Cuma 1 kode voucher per toko per transaksi — kalau client kirim >1 buat toko yang
        // sama, ambil yang pertama saja.
        var voucherCodeByStore = request.Vouchers?
            .GroupBy(v => v.StoreId)
            .ToDictionary(g => g.Key, g => g.First().Code) ?? [];

        var order = new Order
        {
            Id = Guid.NewGuid(),
            OrderNumber = orderNumber,
            UserId = userId,
            AddressId = address.Id,
            Status = OrderStatus.Pending,
            Note = string.IsNullOrWhiteSpace(request.Note) ? null : request.Note,
            RecipientName = address.RecipientName,
            PhoneNumber = address.PhoneNumber,
            FullAddress = address.FullAddress,
            City = address.City,
            Province = address.Province,
            PostalCode = address.PostalCode,
            CreatedAt = now,
            UpdatedAt = now,
        };

        var storeGroups = cartItems.GroupBy(ci => ci.Product.StoreId).ToList();
        var seq = 0;
        foreach (var group in storeGroups)
        {
            seq++;
            var subtotal = group.Sum(ci => PricingHelper.EffectivePrice(ci.Product) * ci.Quantity);
            var commissionAmount = Math.Round(subtotal * commissionPercent / 100m, 2);

            Voucher? voucher = null;
            var voucherDiscount = 0m;
            if (voucherCodeByStore.TryGetValue(group.Key, out var rawCode))
            {
                var code = rawCode.Trim().ToUpperInvariant();
                voucher = await dbContext.Vouchers.SingleOrDefaultAsync(v => v.StoreId == group.Key && v.Code == code);
                var validation = VoucherValidationHelper.Validate(voucher, subtotal, courier.Price, now);
                if (!validation.Valid)
                {
                    return BadRequest(new { message = $"Voucher {code}: {validation.Message}" });
                }
                voucherDiscount = validation.DiscountAmount;
            }

            var subOrder = new SubOrder
            {
                Id = Guid.NewGuid(),
                OrderId = order.Id,
                StoreId = group.Key,
                SubOrderNumber = $"{orderNumber}-{seq}",
                Status = SubOrderStatus.WaitingPayment,
                Subtotal = subtotal,
                ShippingCost = courier.Price,
                VoucherDiscount = voucherDiscount,
                CommissionAmount = commissionAmount,
                SellerEarning = subtotal + courier.Price - commissionAmount - voucherDiscount,
                CreatedAt = now,
                UpdatedAt = now,
            };
            subOrder.StatusHistories.Add(new SubOrderStatusHistory
            {
                Id = Guid.NewGuid(),
                SubOrderId = subOrder.Id,
                Status = SubOrderStatus.WaitingPayment,
                ChangedAt = now,
            });

            if (voucher is not null && voucherDiscount > 0)
            {
                voucher.UsedCount++;
                dbContext.VoucherUsages.Add(new VoucherUsage
                {
                    Id = Guid.NewGuid(),
                    VoucherId = voucher.Id,
                    UserId = userId,
                    SubOrderId = subOrder.Id,
                    DiscountAmount = voucherDiscount,
                    UsedAt = now,
                });
            }

            foreach (var item in group)
            {
                var unitPrice = PricingHelper.EffectivePrice(item.Product);
                order.OrderItems.Add(new OrderItem
                {
                    Id = Guid.NewGuid(),
                    OrderId = order.Id,
                    ProductId = item.ProductId,
                    SubOrderId = subOrder.Id,
                    ProductNameSnapshot = item.Product.Name,
                    UnitPrice = unitPrice,
                    Quantity = item.Quantity,
                    Subtotal = unitPrice * item.Quantity,
                });
            }

            order.SubOrders.Add(subOrder);
        }

        order.ShippingCost = order.SubOrders.Sum(so => so.ShippingCost);
        order.TotalAmount = order.SubOrders.Sum(so => so.Subtotal + so.ShippingCost - so.VoucherDiscount);

        foreach (var item in cartItems)
        {
            item.IsDeleted = true;
            item.UpdatedAt = now;
        }

        dbContext.Orders.Add(order);
        cart!.UpdatedAt = now;
        await dbContext.SaveChangesAsync();

        var storeIds = order.SubOrders.Select(so => so.StoreId).ToList();
        var stores = await dbContext.Stores.Where(s => storeIds.Contains(s.Id)).ToDictionaryAsync(s => s.Id);
        foreach (var subOrder in order.SubOrders)
        {
            subOrder.Store = stores[subOrder.StoreId];
        }

        return Ok(ToDetailDto(order));
    }

    private async Task<string> GenerateOrderNumberAsync()
    {
        var datePart = DateTime.UtcNow.ToString("yyyyMMdd");
        for (var attempt = 0; attempt < 5; attempt++)
        {
            var candidate = $"SHP-{datePart}-{Random.Shared.Next(0, 10000):D4}";
            var exists = await dbContext.Orders.AnyAsync(o => o.OrderNumber == candidate);
            if (!exists)
            {
                return candidate;
            }
        }
        return $"SHP-{datePart}-{Guid.NewGuid().ToString("N")[..4].ToUpperInvariant()}";
    }

    private static OrderDetailDto ToDetailDto(Order order) => new(
        order.Id, order.OrderNumber, order.Status.ToString(), order.TotalAmount, order.Note,
        new OrderAddressSnapshotDto(
            order.RecipientName, order.PhoneNumber, order.FullAddress, order.City, order.Province, order.PostalCode),
        order.SubOrders.Select(SubOrdersController.ToSummaryDto).ToList(),
        order.CreatedAt);
}
