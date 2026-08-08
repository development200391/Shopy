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
public class OrdersController(ShopyDbContext dbContext, INotificationService notificationService) : ControllerBase
{
    // Ongkir flat, sama seperti simulasi di Flutter (`kMockShippingCost`) — belum ada
    // integrasi kurir asli.
    private const decimal FlatShippingCost = 15000m;

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
            .Include(o => o.OrderItems)
            .SingleOrDefaultAsync(o => o.Id == id && o.UserId == userId);
        if (order is null)
        {
            return NotFound(new { message = "Pesanan tidak ditemukan." });
        }

        var history = await GetHistoryAsync(order.Id);
        return Ok(ToDetailDto(order, history));
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

        var subtotal = cartItems.Sum(ci => ci.Product.Price * ci.Quantity);
        var now = DateTime.UtcNow;

        var order = new Order
        {
            Id = Guid.NewGuid(),
            OrderNumber = await GenerateOrderNumberAsync(),
            UserId = userId,
            AddressId = address.Id,
            Status = OrderStatus.Pending,
            ShippingCost = FlatShippingCost,
            TotalAmount = subtotal + FlatShippingCost,
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

        foreach (var item in cartItems)
        {
            order.OrderItems.Add(new OrderItem
            {
                Id = Guid.NewGuid(),
                OrderId = order.Id,
                ProductId = item.ProductId,
                ProductNameSnapshot = item.Product.Name,
                UnitPrice = item.Product.Price,
                Quantity = item.Quantity,
                Subtotal = item.Product.Price * item.Quantity,
            });
            item.IsDeleted = true;
            item.UpdatedAt = now;
        }
        dbContext.Orders.Add(order);

        var statusHistory = new OrderStatusHistory
        {
            Id = Guid.NewGuid(),
            OrderId = order.Id,
            Status = OrderStatus.Pending,
            ChangedAt = now,
        };
        dbContext.OrderStatusHistories.Add(statusHistory);

        cart!.UpdatedAt = now;
        await dbContext.SaveChangesAsync();

        return Ok(ToDetailDto(order, [new OrderStatusHistoryDto(OrderStatus.Pending.ToString(), now)]));
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<ActionResult<OrderDetailDto>> UpdateStatus(Guid id, UpdateOrderStatusRequest request)
    {
        // Catatan: belum ada role seller/admin terpisah di app ini, jadi endpoint ini
        // cuma bisa dipakai user buat pesanan miliknya sendiri (bukan buat "role" lain
        // yang mengelola status beneran) — lihat TASKS.md Fase 4 buat detail.
        var userId = User.GetUserId();
        var order = await dbContext.Orders
            .Include(o => o.OrderItems)
            .SingleOrDefaultAsync(o => o.Id == id && o.UserId == userId);
        if (order is null)
        {
            return NotFound(new { message = "Pesanan tidak ditemukan." });
        }

        if (order.Status == request.Status)
        {
            return BadRequest(new { message = "Pesanan sudah dalam status ini." });
        }

        order.Status = request.Status;
        order.UpdatedAt = DateTime.UtcNow;
        dbContext.OrderStatusHistories.Add(new OrderStatusHistory
        {
            Id = Guid.NewGuid(),
            OrderId = order.Id,
            Status = request.Status,
            ChangedAt = order.UpdatedAt,
        });
        await dbContext.SaveChangesAsync();
        await notificationService.NotifyOrderStatusChangedAsync(order);

        var history = await GetHistoryAsync(order.Id);
        return Ok(ToDetailDto(order, history));
    }

    private async Task<List<OrderStatusHistoryDto>> GetHistoryAsync(Guid orderId)
    {
        return await dbContext.OrderStatusHistories
            .Where(h => h.OrderId == orderId)
            .OrderBy(h => h.ChangedAt)
            .Select(h => new OrderStatusHistoryDto(h.Status.ToString(), h.ChangedAt))
            .ToListAsync();
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

    private static OrderDetailDto ToDetailDto(Order order, IReadOnlyList<OrderStatusHistoryDto> history) => new(
        order.Id, order.OrderNumber, order.Status.ToString(),
        order.TotalAmount - order.ShippingCost, order.ShippingCost, order.TotalAmount, order.Note,
        new OrderAddressSnapshotDto(
            order.RecipientName, order.PhoneNumber, order.FullAddress, order.City, order.Province, order.PostalCode),
        order.OrderItems
            .Select(oi => new OrderItemDto(oi.Id, oi.ProductId, oi.ProductNameSnapshot, oi.UnitPrice, oi.Quantity, oi.Subtotal))
            .ToList(),
        history, order.CreatedAt, order.UpdatedAt);
}
