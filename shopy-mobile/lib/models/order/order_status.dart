/// Status pesanan, sesuai enum `OrderStatus` di backend — dikirim/diterima
/// sebagai nama string (mis. `"Processing"`).
enum OrderStatus {
  pending('Pending', 'Menunggu Konfirmasi'),
  processing('Processing', 'Diproses'),
  shipped('Shipped', 'Dikirim'),
  completed('Completed', 'Selesai'),
  cancelled('Cancelled', 'Dibatalkan');

  final String apiValue;
  final String label;

  const OrderStatus(this.apiValue, this.label);

  static OrderStatus fromApiValue(String value) {
    return OrderStatus.values.firstWhere((s) => s.apiValue == value, orElse: () => OrderStatus.pending);
  }
}
