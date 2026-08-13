class Withdrawal {
  final String id;
  final int amount;
  final int adminFee;
  final int netAmount;
  final String status;
  final String bankName;
  final String accountNumberMasked;
  final DateTime requestedAt;
  final DateTime? processedAt;

  const Withdrawal({
    required this.id,
    required this.amount,
    required this.adminFee,
    required this.netAmount,
    required this.status,
    required this.bankName,
    required this.accountNumberMasked,
    required this.requestedAt,
    this.processedAt,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['id'] as String,
      amount: (json['amount'] as num).round(),
      adminFee: (json['adminFee'] as num).round(),
      netAmount: (json['netAmount'] as num).round(),
      status: json['status'] as String,
      bankName: json['bankName'] as String,
      accountNumberMasked: json['accountNumberMasked'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      processedAt: json['processedAt'] == null ? null : DateTime.parse(json['processedAt'] as String),
    );
  }
}
