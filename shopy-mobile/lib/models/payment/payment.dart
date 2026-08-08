import 'payment_method.dart';
import 'payment_status.dart';

/// Transaksi pembayaran 1 pesanan, sesuai `PaymentDto` di backend.
class Payment {
  final String id;
  final String orderId;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? virtualAccountBank;
  final String? virtualAccountNumber;
  final String? qrCodeUrl;
  final DateTime? expiresAt;
  final int amount;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.orderId,
    required this.method,
    required this.status,
    this.virtualAccountBank,
    this.virtualAccountNumber,
    this.qrCodeUrl,
    this.expiresAt,
    required this.amount,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      method: PaymentMethod.values.firstWhere((m) => m.apiValue == json['method']),
      status: PaymentStatus.fromApiValue(json['status'] as String),
      virtualAccountBank: json['virtualAccountBank'] as String?,
      virtualAccountNumber: json['virtualAccountNumber'] as String?,
      qrCodeUrl: json['qrCodeUrl'] as String?,
      expiresAt: json['expiresAt'] == null ? null : DateTime.parse(json['expiresAt'] as String),
      amount: (json['amount'] as num).round(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
