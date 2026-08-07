/// Item favorit/wishlist milik user.
///
/// Catatan: belum terhubung ke backend (`Backend: endpoint wishlist` di
/// TASKS.md Fase 3 masih belum dikerjakan) — data disimpan in-memory lewat
/// [WishlistNotifier] dan di-seed dengan data contoh agar UI bisa didemokan.
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
}
