/// Status transaksi pembayaran, sesuai enum `PaymentStatus` di backend.
enum PaymentStatus {
  pending('Pending', 'Menunggu Pembayaran'),
  settled('Settled', 'Pembayaran Berhasil'),
  expired('Expired', 'Kedaluwarsa'),
  failed('Failed', 'Gagal'),
  cancelled('Cancelled', 'Dibatalkan');

  final String apiValue;
  final String label;

  const PaymentStatus(this.apiValue, this.label);

  static PaymentStatus fromApiValue(String value) {
    return PaymentStatus.values.firstWhere((s) => s.apiValue == value, orElse: () => PaymentStatus.pending);
  }
}
