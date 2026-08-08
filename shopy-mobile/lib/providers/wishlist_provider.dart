import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wishlist/wishlist_item.dart';
import '../services/wishlist_api_service.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'wishlist_state.dart';

final wishlistApiServiceProvider = Provider<WishlistApiService>((ref) {
  return WishlistApiService(ref.watch(apiClientProvider));
});

final wishlistProvider = NotifierProvider<WishlistNotifier, WishlistState>(WishlistNotifier.new);

class WishlistNotifier extends Notifier<WishlistState> {
  @override
  WishlistState build() {
    _load();
    return const WishlistState(loading: true);
  }

  WishlistApiService get _api => ref.read(wishlistApiServiceProvider);

  Future<void> _load() async {
    try {
      final items = await _api.getWishlist();
      state = state.copyWith(items: items, loading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Muat ulang dari server, mis. setelah error atau lewat pull-to-refresh.
  Future<void> reload() => _load();

  void setViewMode(WishlistViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Dipanggil dari tombol hati (mis. di kartu produk halaman Home/Detail).
  /// Kalau produk sudah ada di wishlist, akan dihapus (toggle off); kalau
  /// belum ada, ditambahkan (toggle on). Cuma `item.productId` yang dipakai —
  /// field lain di [item] diabaikan karena backend yang jadi sumber data asli.
  Future<void> toggleFavorite(WishlistItem item) async {
    final isFavorite = state.isFavorite(item.productId);
    try {
      if (isFavorite) {
        await _api.removeFavorite(item.productId);
        state = state.copyWith(
          items: state.items.where((i) => i.productId != item.productId).toList(),
          clearError: true,
        );
      } else {
        final added = await _api.addFavorite(item.productId);
        state = state.copyWith(items: [...state.items, added], clearError: true);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeItem(String id) async {
    final item = state.items.where((i) => i.id == id).firstOrNull;
    if (item == null) return;

    try {
      await _api.removeFavorite(item.productId);
      state = state.copyWith(
        items: state.items.where((i) => i.id != id).toList(),
        selectedIds: {...state.selectedIds}..remove(id),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void enterSelectionMode(String firstSelectedId) {
    state = state.copyWith(selectionMode: true, selectedIds: {firstSelectedId});
  }

  void exitSelectionMode() {
    state = state.copyWith(selectionMode: false, selectedIds: {});
  }

  void toggleSelected(String id) {
    final next = {...state.selectedIds};
    if (!next.add(id)) next.remove(id);
    if (next.isEmpty) {
      exitSelectionMode();
      return;
    }
    state = state.copyWith(selectedIds: next);
  }

  Future<void> removeSelected() async {
    final ids = {...state.selectedIds};
    final productIds = state.items.where((i) => ids.contains(i.id)).map((i) => i.productId);

    try {
      await Future.wait(productIds.map(_api.removeFavorite));
      state = state.copyWith(
        items: state.items.where((item) => !ids.contains(item.id)).toList(),
        selectionMode: false,
        selectedIds: {},
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Pindahkan item terpilih ke keranjang lewat [CartNotifier], lalu hapus
  /// dari wishlist. Dipanggil dari tombol "+ Keranjang" di mode pilih.
  Future<void> moveSelectedToCart(CartNotifier cartNotifier) async {
    final selected = state.items.where((item) => state.selectedIds.contains(item.id)).toList();

    try {
      for (final item in selected) {
        await cartNotifier.addItem(productId: item.productId);
      }
      await removeSelected();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
