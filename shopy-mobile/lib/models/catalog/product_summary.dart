/// Produk untuk tampilan list/grid (Home, Search), sesuai `ProductListItemDto`
/// di backend. Harga dibulatkan ke int (Rupiah tidak pakai desimal di UI).
class ProductSummary {
  final String id;
  final String name;
  final String slug;
  final int price;
  final String? imageUrl;
  final double ratingAverage;
  final int ratingCount;
  final String categoryId;
  final String categoryName;
  final String storeId;
  final String storeName;
  final String storeSlug;

  const ProductSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.imageUrl,
    required this.ratingAverage,
    required this.ratingCount,
    required this.categoryId,
    required this.categoryName,
    required this.storeId,
    required this.storeName,
    required this.storeSlug,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      price: (json['price'] as num).round(),
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
