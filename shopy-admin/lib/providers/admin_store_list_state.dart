import '../models/store/admin_store.dart';

class AdminStoreListState {
  final AdminStoreStatus? statusFilter;
  final String search;
  final List<AdminStoreListItem> items;
  final int page;
  final int totalCount;
  final bool hasMore;
  final bool loading;
  final String? error;

  const AdminStoreListState({
    this.statusFilter,
    this.search = '',
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.hasMore = false,
    this.loading = false,
    this.error,
  });

  AdminStoreListState copyWith({
    AdminStoreStatus? statusFilter,
    bool clearStatusFilter = false,
    String? search,
    List<AdminStoreListItem>? items,
    int? page,
    int? totalCount,
    bool? hasMore,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AdminStoreListState(
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
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
