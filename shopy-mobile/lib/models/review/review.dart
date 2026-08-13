/// Ulasan pembeli untuk 1 produk, sesuai `ReviewDto` di backend.
class Review {
  final String id;
  final String buyerName;
  final String? buyerAvatarUrl;
  final int rating;
  final String? comment;
  final List<String> imageUrls;
  final String? sellerReply;
  final DateTime? sellerRepliedAt;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.buyerName,
    this.buyerAvatarUrl,
    required this.rating,
    this.comment,
    this.imageUrls = const [],
    this.sellerReply,
    this.sellerRepliedAt,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      buyerName: json['buyerName'] as String,
      buyerAvatarUrl: json['buyerAvatarUrl'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      imageUrls: (json['imageUrls'] as List? ?? []).map((e) => e as String).toList(),
      sellerReply: json['sellerReply'] as String?,
      sellerRepliedAt: json['sellerRepliedAt'] == null ? null : DateTime.parse(json['sellerRepliedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
