class SellerReview {
  final String id;
  final String buyerName;
  final String? buyerAvatarUrl;
  final String productId;
  final String productName;
  final int rating;
  final String? comment;
  final List<String> imageUrls;
  final String? sellerReply;
  final DateTime? sellerRepliedAt;
  final DateTime createdAt;

  const SellerReview({
    required this.id,
    required this.buyerName,
    this.buyerAvatarUrl,
    required this.productId,
    required this.productName,
    required this.rating,
    this.comment,
    required this.imageUrls,
    this.sellerReply,
    this.sellerRepliedAt,
    required this.createdAt,
  });

  bool get isReplied => sellerReply != null;

  factory SellerReview.fromJson(Map<String, dynamic> json) {
    return SellerReview(
      id: json['id'] as String,
      buyerName: json['buyerName'] as String,
      buyerAvatarUrl: json['buyerAvatarUrl'] as String?,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      imageUrls: (json['imageUrls'] as List).map((e) => e as String).toList(),
      sellerReply: json['sellerReply'] as String?,
      sellerRepliedAt: json['sellerRepliedAt'] == null ? null : DateTime.parse(json['sellerRepliedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class RatingDistributionItem {
  final int stars;
  final int count;
  final int percent;

  const RatingDistributionItem({required this.stars, required this.count, required this.percent});

  factory RatingDistributionItem.fromJson(Map<String, dynamic> json) {
    return RatingDistributionItem(
      stars: json['stars'] as int,
      count: json['count'] as int,
      percent: json['percent'] as int,
    );
  }
}

class SellerReviewSummary {
  final double average;
  final int totalCount;
  final int unrepliedCount;
  final List<RatingDistributionItem> distribution;

  const SellerReviewSummary({
    required this.average,
    required this.totalCount,
    required this.unrepliedCount,
    required this.distribution,
  });

  factory SellerReviewSummary.fromJson(Map<String, dynamic> json) {
    return SellerReviewSummary(
      average: (json['average'] as num).toDouble(),
      totalCount: json['totalCount'] as int,
      unrepliedCount: json['unrepliedCount'] as int,
      distribution: (json['distribution'] as List)
          .map((e) => RatingDistributionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
