import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart/cart_item.dart';
import '../services/cart_api_service.dart';
import 'auth_provider.dart';
import 'cart_state.dart';

final cartApiServiceProvider = Provider<CartApiService>((ref) {
  return CartApiService(ref.watch(apiClientProvider));
});

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

/// Total qty barang di keranjang — dipakai untuk badge di [AppBottomNav]
/// supaya ikon keranjang selalu sinkron dengan isi keranjang di layar mana pun.
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.select((state) => state.totalItemCount));
});

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    _load();
    return const CartState(loading: true);
  }

  CartApiService get _api => ref.read(cartApiServiceProvider);

  Future<void> _load() async {
    try {
      final items = await _api.getCart();
      state = state.copyWith(items: items, loading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Muat ulang dari server, mis. setelah error atau lewat pull-to-refresh.
  Future<void> reload() => _load();

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

  Future<void> incrementQty(String id) => _updateQty(id, delta: 1);

  Future<void> decrementQty(String id) => _updateQty(id, delta: -1);

  Future<void> _updateQty(String id, {required int delta}) async {
    final current = state.items.where((item) => item.id == id).firstOrNull;
    if (current == null) return;

    final newQty = current.qty + delta < 1 ? 1 : current.qty + delta;
    if (newQty == current.qty) return;

    try {
      final items = await _api.updateItem(id, newQty);
      state = state.copyWith(items: _mergeSelected(items), clearError: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeItem(String id) async {
    try {
      final items = await _api.removeItem(id);
      state = state.copyWith(items: _mergeSelected(items), clearError: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> clearAll() async {
    try {
      await _api.clearCart();
      state = const CartState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Nambah produk ke keranjang dari luar (mis. tombol "+ Keranjang" di
  /// halaman Wishlist atau Detail Produk). Kalau produk yang sama sudah ada,
  /// qty-nya ditambah alih-alih duplikat (ditangani backend). Sengaja
  /// membiarkan error dilempar ke pemanggil supaya UI bisa nampilin
  /// snackbar sukses/gagal yang sesuai.
  Future<void> addItem({required String productId, int qty = 1}) async {
    final items = await _api.addItem(productId, qty);
    state = state.copyWith(items: _mergeSelected(items), clearError: true);
  }

  /// Data terbaru dari server tidak bawa state pilih (`selected`) checkout —
  /// itu murni state lokal UI. Item yang sudah ada state `selected`-nya
  /// dipertahankan, item baru default terpilih.
  List<CartItem> _mergeSelected(List<CartItem> freshItems) {
    final previousSelected = {for (final item in state.items) item.id: item.selected};
    return [for (final item in freshItems) item.copyWith(selected: previousSelected[item.id] ?? true)];
  }
}
