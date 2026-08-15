namespace shopy_api.Models;

public enum NotificationType
{
    OrderStatus,
    Promo,

    // --- Seller (TASKSELLER.md Fase 8) ---
    NewOrder,
    PaymentReceived,
    LowStock,
    NewReview,
    NewChat,
    Withdrawal,
    VoucherQuota,
}
