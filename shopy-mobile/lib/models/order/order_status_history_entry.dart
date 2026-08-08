import 'order_status.dart';

/// Satu baris jejak perubahan status pesanan, dipakai buat timeline "Lacak Pesanan".
class OrderStatusHistoryEntry {
  final OrderStatus status;
  final DateTime changedAt;

  const OrderStatusHistoryEntry({required this.status, required this.changedAt});

  factory OrderStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryEntry(
      status: OrderStatus.fromApiValue(json['status'] as String),
      changedAt: DateTime.parse(json['changedAt'] as String),
    );
  }
}
