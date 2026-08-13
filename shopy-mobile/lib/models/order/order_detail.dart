import 'order_address_snapshot.dart';
import 'order_status.dart';
import 'sub_order_summary.dart';

/// Ringkasan pesanan induk (lintas toko) — hasil checkout & dipakai buat alur
/// pembayaran (1 pembayaran untuk seluruh toko). Rincian per toko ada di
/// [subOrders]; detail/tracking per toko sendiri dipisah ke `SubOrderDetail`
/// (TASKSELLER.md Fase 4), sesuai `OrderDetailDto` di backend.
class OrderDetail {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final int totalAmount;
  final String? note;
  final OrderAddressSnapshot address;
  final List<SubOrderSummary> subOrders;
  final DateTime createdAt;

  const OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    this.note,
    required this.address,
    required this.subOrders,
    required this.createdAt,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      status: OrderStatus.fromApiValue(json['status'] as String),
      totalAmount: (json['totalAmount'] as num).round(),
      note: json['note'] as String?,
      address: OrderAddressSnapshot.fromJson(json['address'] as Map<String, dynamic>),
      subOrders: (json['subOrders'] as List)
          .map((e) => SubOrderSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
