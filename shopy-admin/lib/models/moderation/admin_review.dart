class AdminReviewListItem {
  final String id;
  final String productId;
  final String productName;
  final String? storeId;
  final String? storeName;
  final String buyerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const AdminReviewListItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.storeId,
    this.storeName,
    required this.buyerName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory AdminReviewListItem.fromJson(Map<String, dynamic> json) {
    return AdminReviewListItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      storeId: json['storeId'] as String?,
      storeName: json['storeName'] as String?,
      buyerName: json['buyerName'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
