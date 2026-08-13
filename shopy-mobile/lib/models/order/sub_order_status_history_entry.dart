import 'sub_order_status.dart';

/// Satu baris jejak perubahan status sub-pesanan, dipakai buat timeline
/// "Lacak Pesanan" per toko.
class SubOrderStatusHistoryEntry {
  final SubOrderStatus status;
  final String? note;
  final DateTime changedAt;

  const SubOrderStatusHistoryEntry({required this.status, this.note, required this.changedAt});

  factory SubOrderStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SubOrderStatusHistoryEntry(
      status: SubOrderStatus.fromApiValue(json['status'] as String),
      note: json['note'] as String?,
      changedAt: DateTime.parse(json['changedAt'] as String),
    );
  }
}
