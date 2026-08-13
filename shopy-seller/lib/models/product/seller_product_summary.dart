class SellerProductSummary {
  final String id;
  final String name;
  final String slug;
  final int price;
  final String? imageUrl;
  final int stock;
  final bool isActive;
  final int soldCount;
  final int? discountPrice;
  final DateTime? discountStartAt;
  final DateTime? discountEndAt;

  const SellerProductSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.imageUrl,
    required this.stock,
    required this.isActive,
    required this.soldCount,
    this.discountPrice,
    this.discountStartAt,
    this.discountEndAt,
  });

  bool get isDiscounted => discountPrice != null;

  factory SellerProductSummary.fromJson(Map<String, dynamic> json) {
    return SellerProductSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      price: (json['price'] as num).round(),
      imageUrl: json['imageUrl'] as String?,
      stock: json['stock'] as int,
      isActive: json['isActive'] as bool,
      soldCount: json['soldCount'] as int,
      discountPrice: (json['discountPrice'] as num?)?.round(),
      discountStartAt: json['discountStartAt'] == null ? null : DateTime.parse(json['discountStartAt'] as String),
      discountEndAt: json['discountEndAt'] == null ? null : DateTime.parse(json['discountEndAt'] as String),
    );
  }
}
