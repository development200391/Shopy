import 'sub_order_status.dart';

/// Ringkasan sub-pesanan (per toko) untuk list di halaman Riwayat Transaksi
/// & ringkasan checkout sukses, sesuai `SubOrderSummaryDto` di backend.
class SubOrderSummary {
  final String id;
  final String subOrderNumber;
  final String orderId;
  final String orderNumber;
  final String storeId;
  final String storeName;
  final String? storeLogoUrl;
  final SubOrderStatus status;
  final int subtotal;
  final int shippingCost;
  final int totalAmount;
  final int itemCount;
  final List<String?> previewImageUrls;
  final DateTime createdAt;

  const SubOrderSummary({
    required this.id,
    required this.subOrderNumber,
    required this.orderId,
    required this.orderNumber,
    required this.storeId,
    required this.storeName,
    this.storeLogoUrl,
    required this.status,
    required this.subtotal,
    required this.shippingCost,
    required this.totalAmount,
    required this.itemCount,
    required this.previewImageUrls,
    required this.createdAt,
  });

  factory SubOrderSummary.fromJson(Map<String, dynamic> json) {
    return SubOrderSummary(
      id: json['id'] as String,
      subOrderNumber: json['subOrderNumber'] as String,
      orderId: json['orderId'] as String,
      orderNumber: json['orderNumber'] as String,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String,
      storeLogoUrl: json['storeLogoUrl'] as String?,
      status: SubOrderStatus.fromApiValue(json['status'] as String),
      subtotal: (json['subtotal'] as num).round(),
      shippingCost: (json['shippingCost'] as num).round(),
      totalAmount: (json['totalAmount'] as num).round(),
      itemCount: json['itemCount'] as int,
      previewImageUrls: (json['previewImageUrls'] as List).map((e) => e as String?).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
