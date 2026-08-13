class Voucher {
  final String id;
  final String code;
  final String type;
  final int value;
  final int? maxDiscount;
  final int? minPurchase;
  final int? quota;
  final int usedCount;
  final DateTime startAt;
  final DateTime endAt;
  final bool isActive;
  final String status;
  final int totalDiscountGiven;
  final int totalOrderValue;

  const Voucher({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.maxDiscount,
    this.minPurchase,
    this.quota,
    required this.usedCount,
    required this.startAt,
    required this.endAt,
    required this.isActive,
    required this.status,
    required this.totalDiscountGiven,
    required this.totalOrderValue,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] as String,
      code: json['code'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).round(),
      maxDiscount: (json['maxDiscount'] as num?)?.round(),
      minPurchase: (json['minPurchase'] as num?)?.round(),
      quota: json['quota'] as int?,
      usedCount: json['usedCount'] as int,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      isActive: json['isActive'] as bool,
      status: json['status'] as String,
      totalDiscountGiven: (json['totalDiscountGiven'] as num).round(),
      totalOrderValue: (json['totalOrderValue'] as num).round(),
    );
  }
}
