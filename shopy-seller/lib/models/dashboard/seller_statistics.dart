import 'seller_dashboard.dart';

class StatisticsMetric {
  final num value;
  final double deltaPercent;

  const StatisticsMetric({required this.value, required this.deltaPercent});

  factory StatisticsMetric.fromJson(Map<String, dynamic> json) {
    return StatisticsMetric(
      value: json['value'] as num,
      deltaPercent: (json['deltaPercent'] as num).toDouble(),
    );
  }
}

class TopProduct {
  final String productId;
  final String productName;
  final String? imageUrl;
  final int quantitySold;
  final int revenue;

  const TopProduct({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.quantitySold,
    required this.revenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      imageUrl: json['imageUrl'] as String?,
      quantitySold: json['quantitySold'] as int,
      revenue: (json['revenue'] as num).round(),
    );
  }
}

/// Statistik penjualan per-periode, sesuai `SellerStatisticsDto` di backend.
class SellerStatistics {
  final DateTime periodStart;
  final DateTime periodEnd;
  final StatisticsMetric omzet;
  final StatisticsMetric orderCount;
  final StatisticsMetric productsSold;
  final StatisticsMetric averageOrder;
  final List<DailySales> dailySeries;
  final List<TopProduct> topProducts;

  const SellerStatistics({
    required this.periodStart,
    required this.periodEnd,
    required this.omzet,
    required this.orderCount,
    required this.productsSold,
    required this.averageOrder,
    required this.dailySeries,
    required this.topProducts,
  });

  factory SellerStatistics.fromJson(Map<String, dynamic> json) {
    return SellerStatistics(
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      omzet: StatisticsMetric.fromJson(json['omzet'] as Map<String, dynamic>),
      orderCount: StatisticsMetric.fromJson(json['orderCount'] as Map<String, dynamic>),
      productsSold: StatisticsMetric.fromJson(json['productsSold'] as Map<String, dynamic>),
      averageOrder: StatisticsMetric.fromJson(json['averageOrder'] as Map<String, dynamic>),
      dailySeries: (json['dailySeries'] as List).map((e) => DailySales.fromJson(e as Map<String, dynamic>)).toList(),
      topProducts: (json['topProducts'] as List).map((e) => TopProduct.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
