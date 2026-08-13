/// Hasil validasi kode voucher toko, sesuai `ValidateVoucherResponse` di backend.
class VoucherValidation {
  final bool valid;
  final String? message;
  final String? voucherId;
  final String? type;
  final int discountAmount;

  const VoucherValidation({
    required this.valid,
    this.message,
    this.voucherId,
    this.type,
    required this.discountAmount,
  });

  factory VoucherValidation.fromJson(Map<String, dynamic> json) {
    return VoucherValidation(
      valid: json['valid'] as bool,
      message: json['message'] as String?,
      voucherId: json['voucherId'] as String?,
      type: json['type'] as String?,
      discountAmount: (json['discountAmount'] as num).round(),
    );
  }
}
