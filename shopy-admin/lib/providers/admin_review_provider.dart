import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_product_provider.dart';
import 'admin_review_list_state.dart';

final adminReviewListProvider =
    NotifierProvider<AdminReviewListNotifier, AdminReviewListState>(AdminReviewListNotifier.new);

class AdminReviewListNotifier extends Notifier<AdminReviewListState> {
  static const int _pageSize = 20;

  @override
  AdminReviewListState build() {
    _fetch(resetItems: true);
    return const AdminReviewListState(loading: true);
  }

  Future<void> setSearch(String search) {
    state = state.copyWith(search: search);
    return _fetch(resetItems: true);
  }

  Future<void> reload() => _fetch(resetItems: true);

  Future<void> loadMore() {
    if (state.loading || !state.hasMore) return Future.value();
    return _fetch(resetItems: false);
  }

  Future<void> _fetch({required bool resetItems}) async {
    final nextPage = resetItems ? 1 : state.page + 1;
    state = state.copyWith(loading: true, clearError: true);

    try {
      final result = await ref
          .read(adminModerationApiServiceProvider)
          .getReviews(search: state.search, page: nextPage, pageSize: _pageSize);
      state = state.copyWith(
        items: resetItems ? result.items : [...state.items, ...result.items],
        page: result.page,
        totalCount: result.totalCount,
        hasMore: result.page * result.pageSize < result.totalCount,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
