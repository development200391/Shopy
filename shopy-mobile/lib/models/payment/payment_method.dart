/// Metode pembayaran yang didukung, sesuai enum `PaymentMethod` di backend.
///
/// Mockup (`07_pembayaran_pilih_metode.png`) juga menampilkan Transfer Mandiri,
/// OVO, dan DANA — sengaja tidak diimplementasikan karena Midtrans Core API
/// butuh endpoint/alur berbeda untuk itu (lihat catatan di
/// `shopy-api/Models/PaymentMethod.cs`).
enum PaymentMethod {
  bcaVa('BcaVa', 'Transfer Bank BCA', 'BCA', 'Transfer Bank'),
  bniVa('BniVa', 'Transfer Bank BNI', 'BNI', 'Transfer Bank'),
  goPay('GoPay', 'GoPay', 'GP', 'E-Wallet'),
  qris('Qris', 'QRIS (semua e-wallet & bank)', 'QR', 'QRIS');

  final String apiValue;
  final String label;
  final String badge;
  final String group;

  const PaymentMethod(this.apiValue, this.label, this.badge, this.group);
}
