import 'order_address_snapshot.dart';
import 'order_line_item.dart';
import 'order_status.dart';
import 'order_status_history_entry.dart';

/// Detail lengkap 1 pesanan, sesuai `OrderDetailDto` di backend.
class OrderDetail {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final int subtotal;
  final int shippingCost;
  final int totalAmount;
  final String? note;
  final OrderAddressSnapshot address;
  final List<OrderLineItem> items;
  final List<OrderStatusHistoryEntry> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.shippingCost,
    required this.totalAmount,
    this.note,
    required this.address,
    required this.items,
    required this.statusHistory,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      status: OrderStatus.fromApiValue(json['status'] as String),
      subtotal: (json['subtotal'] as num).round(),
      shippingCost: (json['shippingCost'] as num).round(),
      totalAmount: (json['totalAmount'] as num).round(),
      note: json['note'] as String?,
      address: OrderAddressSnapshot.fromJson(json['address'] as Map<String, dynamic>),
      items: (json['items'] as List).map((e) => OrderLineItem.fromJson(e as Map<String, dynamic>)).toList(),
      statusHistory: (json['statusHistory'] as List)
          .map((e) => OrderStatusHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
