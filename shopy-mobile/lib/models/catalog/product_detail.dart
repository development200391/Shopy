/// Detail produk, sesuai `ProductDetailDto` di backend.
class ProductDetail {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final int price;
  final int stock;
  final String? imageUrl;
  final double ratingAverage;
  final int ratingCount;
  final String categoryId;
  final String categoryName;
  final String storeId;
  final String storeName;
  final String storeSlug;

  const ProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.ratingAverage,
    required this.ratingCount,
    required this.categoryId,
    required this.categoryName,
    required this.storeId,
    required this.storeName,
    required this.storeSlug,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).round(),
      stock: json['stock'] as int,
      imageUrl: json['imageUrl'] as String?,
      ratingAverage: (json['ratingAverage'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String,
      storeSlug: json['storeSlug'] as String,
    );
  }
}
