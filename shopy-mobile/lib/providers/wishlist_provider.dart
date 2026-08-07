import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wishlist/wishlist_item.dart';
import 'cart_provider.dart';
import 'wishlist_state.dart';

final wishlistProvider = NotifierProvider<WishlistNotifier, WishlistState>(WishlistNotifier.new);

class WishlistNotifier extends Notifier<WishlistState> {
  @override
  WishlistState build() => WishlistState(items: _seedItems());

  static List<WishlistItem> _seedItems() => const [
    WishlistItem(
      id: 'wishlist-1',
      productId: 'product-sneakers-urban-runner',
      name: 'Sepatu Sneakers Urban Runner',
      variant: 'Hitam · Ukuran 41',
      price: 349000,
      rating: 4.6,
    ),
    WishlistItem(
      id: 'wishlist-2',
      productId: 'product-jam-tangan-minimalis',
      name: 'Jam Tangan Minimalis',
      price: 450000,
      rating: 4.9,
    ),
    WishlistItem(
      id: 'wishlist-3',
      productId: 'product-jaket-denim-vintage',
      name: 'Jaket Denim Vintage',
      price: 299000,
      rating: 4.7,
    ),
    WishlistItem(
      id: 'wishlist-4',
      productId: 'product-kacamata-hitam-retro',
      name: 'Kacamata Hitam Retro',
      price: 159000,
      rating: 4.5,
    ),
    WishlistItem(
      id: 'wishlist-5',
      productId: 'product-tas-selempang-kanvas',
      name: 'Tas Selempang Kanvas',
      variant: 'Coklat',
      price: 199000,
      rating: 4.7,
    ),
    WishlistItem(
      id: 'wishlist-6',
      productId: 'product-kaos-oversize-basic',
      name: 'Kaos Oversize Basic',
      variant: 'Putih · Ukuran L',
      price: 129000,
      rating: 4.8,
    ),
  ];

  void setViewMode(WishlistViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Dipanggil dari tombol hati (mis. nanti di kartu produk halaman Home/Detail).
  /// Kalau produk sudah ada di wishlist, akan dihapus (toggle off); kalau
  /// belum ada, [item] ditambahkan (toggle on).
  void toggleFavorite(WishlistItem item) {
    final exists = state.isFavorite(item.productId);
    if (exists) {
      state = state.copyWith(
        items: state.items.where((i) => i.productId != item.productId).toList(),
      );
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
      selectedIds: {...state.selectedIds}..remove(id),
    );
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

  void removeSelected() {
    state = state.copyWith(
      items: state.items.where((item) => !state.selectedIds.contains(item.id)).toList(),
      selectionMode: false,
      selectedIds: {},
    );
  }

  /// Pindahkan item terpilih ke keranjang lewat [CartNotifier], lalu hapus
  /// dari wishlist. Dipanggil dari tombol "+ Keranjang" di mode pilih.
  void moveSelectedToCart(CartNotifier cartNotifier) {
    final selected = state.items.where((item) => state.selectedIds.contains(item.id));
    for (final item in selected) {
      cartNotifier.addItem(
        productId: item.productId,
        name: item.name,
        variant: item.variant.isEmpty ? '-' : item.variant,
        price: item.price,
      );
    }
    removeSelected();
  }
}
