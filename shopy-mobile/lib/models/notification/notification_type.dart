/// Jenis notifikasi, sesuai enum `NotificationType` di backend.
enum NotificationType {
  orderStatus('OrderStatus'),
  promo('Promo');

  final String apiValue;

  const NotificationType(this.apiValue);

  static NotificationType fromApiValue(String value) {
    return NotificationType.values.firstWhere((t) => t.apiValue == value, orElse: () => NotificationType.promo);
  }
}
