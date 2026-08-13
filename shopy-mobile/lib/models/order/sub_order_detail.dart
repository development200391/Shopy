import 'order_address_snapshot.dart';
import 'order_line_item.dart';
import 'sub_order_status.dart';
import 'sub_order_status_history_entry.dart';

/// Detail lengkap 1 sub-pesanan (per toko), sesuai `SubOrderDetailDto` di backend.
class SubOrderDetail {
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
  final int voucherDiscount;
  final int totalAmount;
  final String? courierCode;
  final String? courierService;
  final String? trackingNumber;
  final OrderAddressSnapshot address;
  final String? note;
  final List<OrderLineItem> items;
  final List<SubOrderStatusHistoryEntry> statusHistory;
  final DateTime createdAt;
  final List<String> reviewedProductIds;

  const SubOrderDetail({
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
    this.voucherDiscount = 0,
    required this.totalAmount,
    this.courierCode,
    this.courierService,
    this.trackingNumber,
    required this.address,
    this.note,
    required this.items,
    required this.statusHistory,
    required this.createdAt,
    this.reviewedProductIds = const [],
  });

  factory SubOrderDetail.fromJson(Map<String, dynamic> json) {
    return SubOrderDetail(
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
      voucherDiscount: (json['voucherDiscount'] as num?)?.round() ?? 0,
      totalAmount: (json['totalAmount'] as num).round(),
      courierCode: json['courierCode'] as String?,
      courierService: json['courierService'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      address: OrderAddressSnapshot.fromJson(json['address'] as Map<String, dynamic>),
      note: json['note'] as String?,
      items: (json['items'] as List).map((e) => OrderLineItem.fromJson(e as Map<String, dynamic>)).toList(),
      statusHistory: (json['statusHistory'] as List)
          .map((e) => SubOrderStatusHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewedProductIds: (json['reviewedProductIds'] as List? ?? []).map((e) => e as String).toList(),
    );
  }
}
