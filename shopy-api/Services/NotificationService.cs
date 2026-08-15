using System.Globalization;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;

namespace shopy_api.Services;

public class NotificationService(ShopyDbContext dbContext, IPushNotificationService pushService) : INotificationService
{
    private static readonly CultureInfo IdCulture = CultureInfo.GetCultureInfo("id-ID");

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

    public Task NotifyNewOrderAsync(SubOrder subOrder, Store store) => SendToStoreOwnerAsync(
        store, NotificationType.NewOrder, subOrder.OrderId,
        "Pesanan Baru Masuk",
        $"Pesanan #{subOrder.SubOrderNumber} menunggu konfirmasi kamu.",
        new Dictionary<string, string> { ["type"] = "new_order", ["subOrderId"] = subOrder.Id.ToString() });

    public Task NotifyPaymentReceivedAsync(SubOrder subOrder, Store store)
    {
        var amount = subOrder.Subtotal + subOrder.ShippingCost - subOrder.VoucherDiscount;
        return SendToStoreOwnerAsync(
            store, NotificationType.PaymentReceived, subOrder.OrderId,
            "Pembayaran Diterima",
            $"Pesanan #{subOrder.SubOrderNumber} sudah dibayar Rp{amount.ToString("N0", IdCulture)}.",
            new Dictionary<string, string> { ["type"] = "payment_received", ["subOrderId"] = subOrder.Id.ToString() });
    }

    public Task NotifyLowStockAsync(Product product, Store store) => SendToStoreOwnerAsync(
        store, NotificationType.LowStock, null,
        "Stok Produk Menipis",
        $"{product.Name} tersisa {product.Stock} pcs.",
        new Dictionary<string, string> { ["type"] = "low_stock", ["productId"] = product.Id.ToString() });

    public Task NotifyNewReviewAsync(Review review, Store store, string productName) => SendToStoreOwnerAsync(
        store, NotificationType.NewReview, null,
        "Ulasan Baru",
        $"{review.Rating} bintang untuk {productName}.",
        new Dictionary<string, string> { ["type"] = "new_review", ["reviewId"] = review.Id.ToString() });

    public Task NotifyNewChatAsync(ChatRoom room, Store store, string preview) => SendToStoreOwnerAsync(
        store, NotificationType.NewChat, null,
        "Pesan Baru dari Pembeli",
        string.IsNullOrEmpty(preview) ? "Kamu dapat pesan baru" : preview,
        new Dictionary<string, string> { ["type"] = "new_chat", ["roomId"] = room.Id.ToString() });

    public Task NotifyVoucherQuotaAsync(Voucher voucher, Store store) => SendToStoreOwnerAsync(
        store, NotificationType.VoucherQuota, null,
        "Voucher Hampir Habis",
        $"{voucher.Code} sudah dipakai {voucher.UsedCount} dari {voucher.Quota} kuota.",
        new Dictionary<string, string> { ["type"] = "voucher_quota", ["voucherId"] = voucher.Id.ToString() });

    public Task NotifyWithdrawalCompletedAsync(Withdrawal withdrawal, Store store) => SendToStoreOwnerAsync(
        store, NotificationType.Withdrawal, null,
        "Pencairan Berhasil",
        $"Rp{withdrawal.NetAmount.ToString("N0", IdCulture)} sudah masuk ke rekeningmu.",
        new Dictionary<string, string> { ["type"] = "withdrawal", ["withdrawalId"] = withdrawal.Id.ToString() });

    /// <summary>
    /// Titik tunggal notifikasi seller — insert baris <c>Notification</c> (StoreId terisi,
    /// UserId = pemilik toko) lalu push ke device token yang terdaftar sebagai app Seller
    /// (TASKSELLER.md Fase 8), supaya tidak nyasar ke app pembeli kalau 1 akun login di keduanya.
    /// </summary>
    private async Task SendToStoreOwnerAsync(
        Store store, NotificationType type, Guid? orderId, string title, string body, IReadOnlyDictionary<string, string> data)
    {
        dbContext.Notifications.Add(new Notification
        {
            Id = Guid.NewGuid(),
            UserId = store.OwnerUserId,
            StoreId = store.Id,
            Type = type,
            Title = title,
            Body = body,
            OrderId = orderId,
            CreatedAt = DateTime.UtcNow,
        });
        await dbContext.SaveChangesAsync();

        var tokens = await dbContext.DeviceTokens
            .Where(t => t.UserId == store.OwnerUserId && t.AppType == DeviceTokenAppType.Seller)
            .Select(t => t.Token)
            .ToListAsync();
        await pushService.SendAsync(tokens, title, body, data);
    }
}
