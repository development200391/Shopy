class SellerOrderSummary {
  final String id;
  final String subOrderNumber;
  final String status;
  final String buyerName;
  final int itemCount;
  final List<String?> previewImageUrls;
  final int totalAmount;
  final DateTime? autoCancelAt;
  final DateTime createdAt;

  const SellerOrderSummary({
    required this.id,
    required this.subOrderNumber,
    required this.status,
    required this.buyerName,
    required this.itemCount,
    required this.previewImageUrls,
    required this.totalAmount,
    this.autoCancelAt,
    required this.createdAt,
  });

  factory SellerOrderSummary.fromJson(Map<String, dynamic> json) {
    return SellerOrderSummary(
      id: json['id'] as String,
      subOrderNumber: json['subOrderNumber'] as String,
      status: json['status'] as String,
      buyerName: json['buyerName'] as String,
      itemCount: json['itemCount'] as int,
      previewImageUrls: (json['previewImageUrls'] as List).map((e) => e as String?).toList(),
      totalAmount: (json['totalAmount'] as num).round(),
      autoCancelAt: json['autoCancelAt'] == null ? null : DateTime.parse(json['autoCancelAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
