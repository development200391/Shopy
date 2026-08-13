class ProductImage {
  final String id;
  final String url;
  final int sortOrder;
  final bool isPrimary;

  const ProductImage({
    required this.id,
    required this.url,
    required this.sortOrder,
    required this.isPrimary,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as String,
      url: json['url'] as String,
      sortOrder: json['sortOrder'] as int,
      isPrimary: json['isPrimary'] as bool,
    );
  }
}
