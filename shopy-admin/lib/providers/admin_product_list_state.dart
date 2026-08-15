import '../models/moderation/admin_product.dart';

class AdminProductListState {
  final String search;
  final List<AdminProductListItem> items;
  final int page;
  final int totalCount;
  final bool hasMore;
  final bool loading;
  final String? error;

  const AdminProductListState({
    this.search = '',
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.hasMore = false,
    this.loading = false,
    this.error,
  });

  AdminProductListState copyWith({
    String? search,
    List<AdminProductListItem>? items,
    int? page,
    int? totalCount,
    bool? hasMore,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AdminProductListState(
      search: search ?? this.search,
      items: items ?? this.items,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
