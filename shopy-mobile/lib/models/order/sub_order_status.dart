/// Status sub-pesanan per toko, sesuai enum `SubOrderStatus` di backend —
/// dikirim/diterima sebagai nama string (mis. `"Processing"`).
enum SubOrderStatus {
  waitingPayment('WaitingPayment', 'Menunggu Pembayaran'),
  newOrder('NewOrder', 'Menunggu Konfirmasi Toko'),
  processing('Processing', 'Diproses'),
  shipped('Shipped', 'Dikirim'),
  completed('Completed', 'Selesai'),
  cancelled('Cancelled', 'Dibatalkan'),
  rejected('Rejected', 'Ditolak Penjual');

  final String apiValue;
  final String label;

  const SubOrderStatus(this.apiValue, this.label);

  static SubOrderStatus fromApiValue(String value) {
    return SubOrderStatus.values.firstWhere((s) => s.apiValue == value, orElse: () => SubOrderStatus.waitingPayment);
  }
}
