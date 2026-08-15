class NeedsFollowUp {
  final int newOrders;
  final int readyToShip;
  final int lowStockCount;
  final int unrepliedReviews;

  const NeedsFollowUp({
    required this.newOrders,
    required this.readyToShip,
    required this.lowStockCount,
    required this.unrepliedReviews,
  });

  factory NeedsFollowUp.fromJson(Map<String, dynamic> json) {
    return NeedsFollowUp(
      newOrders: json['newOrders'] as int,
      readyToShip: json['readyToShip'] as int,
      lowStockCount: json['lowStockCount'] as int,
      unrepliedReviews: json['unrepliedReviews'] as int,
    );
  }
}

class DailySales {
  final DateTime date;
  final int total;

  const DailySales({required this.date, required this.total});

  factory DailySales.fromJson(Map<String, dynamic> json) {
    return DailySales(date: DateTime.parse(json['date'] as String), total: (json['total'] as num).round());
  }
}

/// Ringkasan dashboard seller, sesuai `SellerDashboardDto` di backend.
class SellerDashboard {
  final int availableBalance;
  final int pendingBalance;
  final int newOrders;
  final int productsSoldToday;
  final int storeVisitors;
  final int incomeToday;
  final NeedsFollowUp needsFollowUp;
  final List<DailySales> sales7Days;

  const SellerDashboard({
    required this.availableBalance,
    required this.pendingBalance,
    required this.newOrders,
    required this.productsSoldToday,
    required this.storeVisitors,
    required this.incomeToday,
    required this.needsFollowUp,
    required this.sales7Days,
  });

  factory SellerDashboard.fromJson(Map<String, dynamic> json) {
    return SellerDashboard(
      availableBalance: (json['availableBalance'] as num).round(),
      pendingBalance: (json['pendingBalance'] as num).round(),
      newOrders: json['newOrders'] as int,
      productsSoldToday: json['productsSoldToday'] as int,
      storeVisitors: json['storeVisitors'] as int,
      incomeToday: (json['incomeToday'] as num).round(),
      needsFollowUp: NeedsFollowUp.fromJson(json['needsFollowUp'] as Map<String, dynamic>),
      sales7Days: (json['sales7Days'] as List).map((e) => DailySales.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
