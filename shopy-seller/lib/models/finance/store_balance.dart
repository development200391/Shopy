class StoreBalance {
  final int availableBalance;
  final int pendingBalance;
  final int totalEarning;
  final int monthlyEarning;
  final int monthlyCommission;
  final int completedOrderCountThisMonth;

  const StoreBalance({
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarning,
    required this.monthlyEarning,
    required this.monthlyCommission,
    required this.completedOrderCountThisMonth,
  });

  factory StoreBalance.fromJson(Map<String, dynamic> json) {
    return StoreBalance(
      availableBalance: (json['availableBalance'] as num).round(),
      pendingBalance: (json['pendingBalance'] as num).round(),
      totalEarning: (json['totalEarning'] as num).round(),
      monthlyEarning: (json['monthlyEarning'] as num).round(),
      monthlyCommission: (json['monthlyCommission'] as num).round(),
      completedOrderCountThisMonth: json['completedOrderCountThisMonth'] as int,
    );
  }
}
