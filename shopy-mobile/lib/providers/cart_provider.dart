import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart/cart_item.dart';
import 'cart_state.dart';

/// Kode voucher contoh yang dipakai untuk mendemokan alur promo di UI.
/// Nanti diganti validasi lewat backend saat endpoint cart/promo sudah ada.
const String kMockPromoCode = 'HEMAT20';
const int kMockPromoDiscount = 20000;

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

/// Total qty barang di keranjang — dipakai untuk badge di [AppBottomNav]
/// supaya ikon keranjang selalu sinkron dengan isi keranjang di layar mana pun.
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.select((state) => state.totalItemCount));
});

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => CartState(items: _seedItems());

  static List<CartItem> _seedItems() => const [
    CartItem(
      id: 'cart-1',
      productId: 'product-sneakers-urban-runner',
      name: 'Sepatu Sneakers Urban Runner',
      variant: 'Hitam · Ukuran 41',
      price: 349000,
      qty: 1,
    ),
    CartItem(
      id: 'cart-2',
      productId: 'product-kaos-oversize-basic',
      name: 'Kaos Oversize Basic',
      variant: 'Putih · Ukuran L',
      price: 129000,
      qty: 2,
    ),
    CartItem(
      id: 'cart-3',
      productId: 'product-tas-selempang-kanvas',
      name: 'Tas Selempang Kanvas',
      variant: 'Coklat',
      price: 199000,
      qty: 1,
    ),
  ];

  void toggleItemSelected(String id) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == id) item.copyWith(selected: !item.selected) else item,
      ],
    );
  }

  void toggleSelectAll() {
    final selectAll = !state.allSelected;
    state = state.copyWith(items: [for (final item in state.items) item.copyWith(selected: selectAll)]);
  }

  void incrementQty(String id) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == id) item.copyWith(qty: item.qty + 1) else item,
      ],
    );
  }

  void decrementQty(String id) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == id) item.copyWith(qty: item.qty > 1 ? item.qty - 1 : 1) else item,
      ],
    );
  }

  void removeItem(String id) {
    final remaining = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(items: remaining, clearPromo: remaining.isEmpty);
  }

  void clearAll() {
    state = const CartState();
  }

  /// Nambah produk ke keranjang dari luar (mis. tombol "+ Keranjang" di
  /// halaman Wishlist atau, nanti, dari halaman Detail Produk). Kalau produk
  /// dengan varian yang sama sudah ada, qty-nya ditambah alih-alih duplikat.
  void addItem({
    required String productId,
    required String name,
    required String variant,
    required int price,
    int qty = 1,
  }) {
    final existingIndex = state.items.indexWhere(
      (item) => item.productId == productId && item.variant == variant,
    );

    if (existingIndex != -1) {
      final existing = state.items[existingIndex];
      state = state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == existing.id) item.copyWith(qty: item.qty + qty) else item,
        ],
      );
      return;
    }

    final newItem = CartItem(
      id: 'cart-${DateTime.now().microsecondsSinceEpoch}',
      productId: productId,
      name: name,
      variant: variant,
      price: price,
      qty: qty,
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  /// Return true kalau kode valid & berhasil diterapkan.
  bool applyPromoCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized != kMockPromoCode) return false;
    state = state.copyWith(promoCode: normalized, promoDiscount: kMockPromoDiscount);
    return true;
  }

  void clearPromo() {
    state = state.copyWith(clearPromo: true);
  }
}
