import '../models/wishlist/wishlist_item.dart';

enum WishlistViewMode { grid, list }

class WishlistState {
  final List<WishlistItem> items;
  final WishlistViewMode viewMode;
  final bool selectionMode;
  final Set<String> selectedIds;

  const WishlistState({
    this.items = const [],
    this.viewMode = WishlistViewMode.grid,
    this.selectionMode = false,
    this.selectedIds = const {},
  });

  bool get isEmpty => items.isEmpty;

  bool isFavorite(String productId) => items.any((item) => item.productId == productId);

  bool isSelected(String id) => selectedIds.contains(id);

  int get selectedCount => selectedIds.length;

  WishlistState copyWith({
    List<WishlistItem>? items,
    WishlistViewMode? viewMode,
    bool? selectionMode,
    Set<String>? selectedIds,
  }) {
    return WishlistState(
      items: items ?? this.items,
      viewMode: viewMode ?? this.viewMode,
      selectionMode: selectionMode ?? this.selectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}
