import 'product_image.dart';

class SellerProductDetail {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final int price;
  final int stock;
  final int weight;
  final String condition;
  final String categoryId;
  final String categoryName;
  final bool isActive;
  final List<ProductImage> images;

  const SellerProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    required this.stock,
    required this.weight,
    required this.condition,
    required this.categoryId,
    required this.categoryName,
    required this.isActive,
    required this.images,
  });

  factory SellerProductDetail.fromJson(Map<String, dynamic> json) {
    return SellerProductDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).round(),
      stock: json['stock'] as int,
      weight: json['weight'] as int,
      condition: json['condition'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      isActive: json['isActive'] as bool,
      images: (json['images'] as List)
          .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
