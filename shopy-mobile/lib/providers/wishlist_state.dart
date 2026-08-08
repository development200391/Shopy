import '../models/wishlist/wishlist_item.dart';

enum WishlistViewMode { grid, list }

class WishlistState {
  final List<WishlistItem> items;
  final WishlistViewMode viewMode;
  final bool selectionMode;
  final Set<String> selectedIds;
  final bool loading;
  final String? error;

  const WishlistState({
    this.items = const [],
    this.viewMode = WishlistViewMode.grid,
    this.selectionMode = false,
    this.selectedIds = const {},
    this.loading = false,
    this.error,
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
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return WishlistState(
      items: items ?? this.items,
      viewMode: viewMode ?? this.viewMode,
      selectionMode: selectionMode ?? this.selectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
