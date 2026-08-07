/// Item di dalam keranjang belanja.
///
/// Catatan: belum terhubung ke backend (endpoint `Backend: endpoint cart` di
/// TASKS.md Fase 3 masih belum dikerjakan) — data disimpan in-memory lewat
/// [CartNotifier] dan di-seed dengan data contoh agar UI bisa didemokan.
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
