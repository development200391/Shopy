/// Jenis notifikasi, sesuai enum `NotificationType` di backend. Nilai
/// seller-only (TASKSELLER.md Fase 8) ditambahkan di bawah nilai lama.
enum NotificationType {
  orderStatus('OrderStatus'),
  promo('Promo'),
  newOrder('NewOrder'),
  paymentReceived('PaymentReceived'),
  lowStock('LowStock'),
  newReview('NewReview'),
  newChat('NewChat'),
  withdrawal('Withdrawal'),
  voucherQuota('VoucherQuota');

  final String apiValue;

  const NotificationType(this.apiValue);

  static NotificationType fromApiValue(String value) {
    return NotificationType.values.firstWhere((t) => t.apiValue == value, orElse: () => NotificationType.promo);
  }
}
