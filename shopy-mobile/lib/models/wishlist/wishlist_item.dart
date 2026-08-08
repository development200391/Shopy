/// Item favorit/wishlist milik user.
class WishlistItem {
  final String id;
  final String productId;
  final String name;
  final String variant;
  final int price;
  final double rating;

  const WishlistItem({
    required this.id,
    required this.productId,
    required this.name,
    this.variant = '',
    required this.price,
    required this.rating,
  });

  /// Parse dari `WishlistItemDto` backend (`GET/POST /api/wishlist`).
  /// Backend belum punya konsep varian produk, jadi selalu kosong.
  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      name: json['productName'] as String,
      price: (json['price'] as num).round(),
      rating: (json['ratingAverage'] as num).toDouble(),
    );
  }
}
