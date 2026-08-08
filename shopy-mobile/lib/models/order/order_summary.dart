import 'order_status.dart';

/// Ringkasan pesanan untuk list di halaman Riwayat Transaksi, sesuai
/// `OrderSummaryDto` di backend.
class OrderSummary {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final int totalAmount;
  final int itemCount;
  final List<String?> previewImageUrls;
  final DateTime createdAt;

  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.itemCount,
    required this.previewImageUrls,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      status: OrderStatus.fromApiValue(json['status'] as String),
      totalAmount: (json['totalAmount'] as num).round(),
      itemCount: json['itemCount'] as int,
      previewImageUrls: (json['previewImageUrls'] as List).map((e) => e as String?).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
