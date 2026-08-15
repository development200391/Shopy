using shopy_api.Models;

namespace shopy_api.Services;

public interface INotificationService
{
    Task NotifySubOrderStatusChangedAsync(SubOrder subOrder, Store store);

    Task<int> BroadcastPromoAsync(string title, string body);

    // --- Seller (TASKSELLER.md Fase 8) ---
    Task NotifyNewOrderAsync(SubOrder subOrder, Store store);

    Task NotifyPaymentReceivedAsync(SubOrder subOrder, Store store);

    Task NotifyLowStockAsync(Product product, Store store);

    Task NotifyNewReviewAsync(Review review, Store store, string productName);

    Task NotifyNewChatAsync(ChatRoom room, Store store, string preview);

    Task NotifyVoucherQuotaAsync(Voucher voucher, Store store);

    /// <remarks>Belum ada pemanggil — pemrosesan withdrawal admin baru dikerjakan di Fase 9.</remarks>
    Task NotifyWithdrawalCompletedAsync(Withdrawal withdrawal, Store store);
}
