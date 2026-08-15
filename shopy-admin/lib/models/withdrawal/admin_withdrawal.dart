enum AdminWithdrawalStatus { pending, processing, completed, rejected }

AdminWithdrawalStatus parseWithdrawalStatus(String raw) {
  switch (raw) {
    case 'Processing':
      return AdminWithdrawalStatus.processing;
    case 'Completed':
      return AdminWithdrawalStatus.completed;
    case 'Rejected':
      return AdminWithdrawalStatus.rejected;
    case 'Pending':
    default:
      return AdminWithdrawalStatus.pending;
  }
}

extension AdminWithdrawalStatusX on AdminWithdrawalStatus {
  /// Nilai yang dikirim ke `?status=`/body `PATCH` — cocok persis string enum backend.
  String get apiValue => switch (this) {
    AdminWithdrawalStatus.pending => 'Pending',
    AdminWithdrawalStatus.processing => 'Processing',
    AdminWithdrawalStatus.completed => 'Completed',
    AdminWithdrawalStatus.rejected => 'Rejected',
  };

  String get label => switch (this) {
    AdminWithdrawalStatus.pending => 'Menunggu',
    AdminWithdrawalStatus.processing => 'Diproses',
    AdminWithdrawalStatus.completed => 'Selesai',
    AdminWithdrawalStatus.rejected => 'Ditolak',
  };
}

/// Sesuai `AdminWithdrawalListItemDto` di backend.
class AdminWithdrawalListItem {
  final String id;
  final String storeName;
  final int amount;
  final int adminFee;
  final int netAmount;
  final AdminWithdrawalStatus status;
  final String bankName;
  final String accountNumberMasked;
  final DateTime requestedAt;
  final DateTime? processedAt;

  const AdminWithdrawalListItem({
    required this.id,
    required this.storeName,
    required this.amount,
    required this.adminFee,
    required this.netAmount,
    required this.status,
    required this.bankName,
    required this.accountNumberMasked,
    required this.requestedAt,
    this.processedAt,
  });

  factory AdminWithdrawalListItem.fromJson(Map<String, dynamic> json) {
    return AdminWithdrawalListItem(
      id: json['id'] as String,
      storeName: json['storeName'] as String,
      amount: (json['amount'] as num).round(),
      adminFee: (json['adminFee'] as num).round(),
      netAmount: (json['netAmount'] as num).round(),
      status: parseWithdrawalStatus(json['status'] as String),
      bankName: json['bankName'] as String,
      accountNumberMasked: json['accountNumberMasked'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      processedAt: json['processedAt'] == null ? null : DateTime.parse(json['processedAt'] as String),
    );
  }
}
