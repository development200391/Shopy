import '../models/moderation/admin_review.dart';

class AdminReviewListState {
  final String search;
  final List<AdminReviewListItem> items;
  final int page;
  final int totalCount;
  final bool hasMore;
  final bool loading;
  final String? error;

  const AdminReviewListState({
    this.search = '',
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.hasMore = false,
    this.loading = false,
    this.error,
  });

  AdminReviewListState copyWith({
    String? search,
    List<AdminReviewListItem>? items,
    int? page,
    int? totalCount,
    bool? hasMore,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AdminReviewListState(
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
