class AdminProductListItem {
  final String id;
  final String name;
  final String? imageUrl;
  final int price;
  final int stock;
  final bool isActive;
  final String storeId;
  final String storeName;
  final double ratingAverage;
  final int ratingCount;
  final DateTime createdAt;

  const AdminProductListItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.stock,
    required this.isActive,
    required this.storeId,
    required this.storeName,
    required this.ratingAverage,
    required this.ratingCount,
    required this.createdAt,
  });

  factory AdminProductListItem.fromJson(Map<String, dynamic> json) {
    return AdminProductListItem(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      price: (json['price'] as num).round(),
      stock: json['stock'] as int,
      isActive: json['isActive'] as bool,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String,
      ratingAverage: (json['ratingAverage'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
