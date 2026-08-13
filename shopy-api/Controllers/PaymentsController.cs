using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Payments;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize]
[Route("api/orders/{orderId:guid}/payments")]
public class PaymentsController(
    ShopyDbContext dbContext, IMidtransService midtransService, INotificationService notificationService, IConfiguration configuration) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<PaymentDto>> CreatePayment(Guid orderId, CreatePaymentRequest request)
    {
        if (!midtransService.IsConfigured)
        {
            return Problem("Payment gateway belum dikonfigurasi di server.", statusCode: StatusCodes.Status503ServiceUnavailable);
        }

        var userId = User.GetUserId();
        var order = await dbContext.Orders.SingleOrDefaultAsync(o => o.Id == orderId && o.UserId == userId);
        if (order is null)
        {
            return NotFound(new { message = "Pesanan tidak ditemukan." });
        }

        if (order.Status != OrderStatus.Pending)
        {
            return BadRequest(new { message = "Pesanan ini tidak bisa/perlu dibayar lagi." });
        }

        // Kalau masih ada transaksi pending yang belum expired untuk metode yang sama,
        // pakai itu lagi alih-alih bikin charge baru ke Midtrans (idempotent).
        var existing = await dbContext.Payments
            .Where(p => p.OrderId == orderId && p.Status == PaymentStatus.Pending)
            .OrderByDescending(p => p.CreatedAt)
            .FirstOrDefaultAsync();
        if (existing is not null
            && existing.Method == request.Method
            && (existing.ExpiresAt is null || existing.ExpiresAt > DateTime.UtcNow))
        {
            return Ok(ToDto(existing));
        }

        var attemptCount = await dbContext.Payments.CountAsync(p => p.OrderId == orderId);
        var midtransOrderId = $"{order.OrderNumber}-P{attemptCount + 1}";

        MidtransChargeResult charge;
        try
        {
            charge = await midtransService.ChargeAsync(midtransOrderId, order.TotalAmount, request.Method);
        }
        catch (InvalidOperationException ex)
        {
            return Problem(ex.Message, statusCode: StatusCodes.Status502BadGateway);
        }

        var now = DateTime.UtcNow;
        var payment = new Payment
        {
            Id = Guid.NewGuid(),
            OrderId = order.Id,
            Method = request.Method,
            MidtransOrderId = midtransOrderId,
            MidtransTransactionId = charge.TransactionId,
            Status = MapStatus(charge.TransactionStatus, null),
            Amount = order.TotalAmount,
            VirtualAccountBank = charge.VaBank,
            VirtualAccountNumber = charge.VaNumber,
            QrCodeUrl = charge.QrCodeUrl,
            ExpiresAt = charge.ExpiryTime,
            CreatedAt = now,
            UpdatedAt = now,
        };
        dbContext.Payments.Add(payment);
        await dbContext.SaveChangesAsync();

        return Ok(ToDto(payment));
    }

    [HttpGet("latest")]
    public async Task<ActionResult<PaymentDto>> GetLatest(Guid orderId)
    {
        var userId = User.GetUserId();
        var order = await dbContext.Orders.SingleOrDefaultAsync(o => o.Id == orderId && o.UserId == userId);
        if (order is null)
        {
            return NotFound(new { message = "Pesanan tidak ditemukan." });
        }

        var payment = await LatestPaymentAsync(orderId);
        if (payment is null)
        {
            return NotFound(new { message = "Belum ada transaksi pembayaran untuk pesanan ini." });
        }

        return Ok(ToDto(payment));
    }

    /// <summary>
    /// Cek manual ke Midtrans ("Cek Status Pembayaran" di mockup) — pelengkap webhook,
    /// karena webhook Midtrans tidak bisa menjangkau backend yang jalan di localhost
    /// tanpa tunnel publik (mis. ngrok) saat development.
    /// </summary>
    [HttpPost("latest/refresh")]
    public async Task<ActionResult<PaymentDto>> RefreshLatest(Guid orderId)
    {
        if (!midtransService.IsConfigured)
        {
            return Problem("Payment gateway belum dikonfigurasi di server.", statusCode: StatusCodes.Status503ServiceUnavailable);
        }

        var userId = User.GetUserId();
        var order = await dbContext.Orders
            .Include(o => o.SubOrders).ThenInclude(so => so.Store)
            .SingleOrDefaultAsync(o => o.Id == orderId && o.UserId == userId);
        if (order is null)
        {
            return NotFound(new { message = "Pesanan tidak ditemukan." });
        }

        var payment = await LatestPaymentAsync(orderId);
        if (payment is null)
        {
            return NotFound(new { message = "Belum ada transaksi pembayaran untuk pesanan ini." });
        }

        MidtransStatusResult status;
        try
        {
            status = await midtransService.GetStatusAsync(payment.MidtransOrderId);
        }
        catch (InvalidOperationException ex)
        {
            return Problem(ex.Message, statusCode: StatusCodes.Status502BadGateway);
        }

        var changedSubOrders = await ApplyStatusAsync(payment, order, status.TransactionStatus, status.FraudStatus);
        await dbContext.SaveChangesAsync();
        foreach (var subOrder in changedSubOrders)
        {
            await notificationService.NotifySubOrderStatusChangedAsync(subOrder, subOrder.Store);
        }

        return Ok(ToDto(payment));
    }

    /// <summary>
    /// Notifikasi status dari Midtrans. Tidak pakai `[Authorize]` karena Midtrans yang
    /// manggil endpoint ini langsung (tidak punya JWT kita) — keasliannya diverifikasi
    /// lewat `signature_key` (SHA512), bukan bearer token.
    /// </summary>
    [AllowAnonymous]
    [HttpPost("/api/payments/webhook")]
    public async Task<IActionResult> Webhook([FromBody] JsonElement body)
    {
        var orderIdParam = body.GetProperty("order_id").GetString();
        var statusCode = body.GetProperty("status_code").GetString();
        var grossAmount = body.GetProperty("gross_amount").GetString();
        var signatureKey = body.GetProperty("signature_key").GetString();
        var transactionStatus = body.GetProperty("transaction_status").GetString();
        var fraudStatus = body.TryGetProperty("fraud_status", out var f) ? f.GetString() : null;

        if (orderIdParam is null || statusCode is null || grossAmount is null || signatureKey is null || transactionStatus is null)
        {
            return BadRequest();
        }

        if (!midtransService.VerifySignature(orderIdParam, statusCode, grossAmount, signatureKey))
        {
            return Unauthorized();
        }

        var payment = await dbContext.Payments
            .Include(p => p.Order).ThenInclude(o => o.SubOrders).ThenInclude(so => so.Store)
            .SingleOrDefaultAsync(p => p.MidtransOrderId == orderIdParam);
        if (payment is null)
        {
            return NotFound();
        }

        var changedSubOrders = await ApplyStatusAsync(payment, payment.Order, transactionStatus, fraudStatus);
        await dbContext.SaveChangesAsync();
        foreach (var subOrder in changedSubOrders)
        {
            await notificationService.NotifySubOrderStatusChangedAsync(subOrder, subOrder.Store);
        }

        return Ok();
    }

    private Task<Payment?> LatestPaymentAsync(Guid orderId)
    {
        return dbContext.Payments
            .Where(p => p.OrderId == orderId)
            .OrderByDescending(p => p.CreatedAt)
            .FirstOrDefaultAsync();
    }

    /// <returns>Sub-order yang statusnya ikut berubah (perlu dikirim notifikasi per item).</returns>
    private Task<List<SubOrder>> ApplyStatusAsync(Payment payment, Order order, string transactionStatus, string? fraudStatus)
    {
        var newStatus = MapStatus(transactionStatus, fraudStatus);
        if (payment.Status == newStatus)
        {
            return Task.FromResult(new List<SubOrder>());
        }

        payment.Status = newStatus;
        payment.UpdatedAt = DateTime.UtcNow;

        var changed = new List<SubOrder>();
        // Pembayaran sukses = tiap sub-order toko maju dari WaitingPayment -> NewOrder,
        // lalu seller yang accept/reject dari sana (lihat SellerOrdersController).
        if (newStatus == PaymentStatus.Settled)
        {
            var now = DateTime.UtcNow;
            var autoCancelHours = configuration.GetValue("Platform:AutoCancelHours", 24);
            foreach (var subOrder in order.SubOrders.Where(so => so.Status == SubOrderStatus.WaitingPayment))
            {
                subOrder.Status = SubOrderStatus.NewOrder;
                subOrder.UpdatedAt = now;
                subOrder.AutoCancelAt = now.AddHours(autoCancelHours);
                dbContext.SubOrderStatusHistories.Add(new SubOrderStatusHistory
                {
                    Id = Guid.NewGuid(),
                    SubOrderId = subOrder.Id,
                    Status = SubOrderStatus.NewOrder,
                    ChangedAt = now,
                });
                changed.Add(subOrder);
            }

            if (changed.Count > 0)
            {
                order.Status = OrderStatusHelper.Recalculate(order.SubOrders.Select(so => so.Status));
                order.UpdatedAt = now;
            }
        }

        return Task.FromResult(changed);
    }

    private static PaymentStatus MapStatus(string transactionStatus, string? fraudStatus) => transactionStatus switch
    {
        "capture" when fraudStatus is null or "accept" => PaymentStatus.Settled,
        "capture" => PaymentStatus.Failed,
        "settlement" => PaymentStatus.Settled,
        "pending" => PaymentStatus.Pending,
        "deny" or "failure" => PaymentStatus.Failed,
        "cancel" => PaymentStatus.Cancelled,
        "expire" => PaymentStatus.Expired,
        _ => PaymentStatus.Pending,
    };

    private static PaymentDto ToDto(Payment p) => new(
        p.Id, p.OrderId, p.Method.ToString(), p.Status.ToString(),
        p.VirtualAccountBank, p.VirtualAccountNumber, p.QrCodeUrl, p.ExpiresAt, p.Amount, p.CreatedAt);
}
