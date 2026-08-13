/// Satu baris buku besar mutasi saldo toko, sesuai `BalanceTransactionDto` di backend.
/// `type` mentah dari backend (`SaleIncome`/`Commission`/`Withdrawal`/`WithdrawalFee`/`Refund`/
/// `Adjustment`) — arah panah di UI cukup ditentukan dari tanda `amount`.
class BalanceTransaction {
  final String id;
  final String type;
  final int amount;
  final int balanceAfter;
  final String? description;
  final DateTime createdAt;

  const BalanceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    required this.createdAt,
  });

  bool get isIncoming => amount >= 0;

  factory BalanceTransaction.fromJson(Map<String, dynamic> json) {
    return BalanceTransaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).round(),
      balanceAfter: (json['balanceAfter'] as num).round(),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
