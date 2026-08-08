/// Item di dalam keranjang belanja.
class CartItem {
  final String id;
  final String productId;
  final String name;
  final String variant;
  final int price;
  final int qty;
  final bool selected;

  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.variant,
    required this.price,
    this.qty = 1,
    this.selected = true,
  });

  int get subtotal => price * qty;

  /// Parse dari `CartItemDto` backend (`GET/POST/PUT/DELETE /api/cart...`).
  /// Backend belum punya konsep varian produk, jadi selalu kosong. `selected`
  /// (state pilih di UI checkout) tidak ada di backend — default `true`,
  /// nilai sebenarnya dijaga lewat merge di [CartNotifier].
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      name: json['productName'] as String,
      variant: '',
      price: (json['price'] as num).round(),
      qty: json['quantity'] as int,
    );
  }

  CartItem copyWith({int? qty, bool? selected}) {
    return CartItem(
      id: id,
      productId: productId,
      name: name,
      variant: variant,
      price: price,
      qty: qty ?? this.qty,
      selected: selected ?? this.selected,
    );
  }
}
