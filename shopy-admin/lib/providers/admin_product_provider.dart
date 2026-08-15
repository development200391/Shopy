import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/admin_moderation_api_service.dart';
import 'admin_product_list_state.dart';
import 'auth_provider.dart';

final adminModerationApiServiceProvider = Provider<AdminModerationApiService>((ref) {
  return AdminModerationApiService(ref.watch(apiClientProvider));
});

final adminProductListProvider =
    NotifierProvider<AdminProductListNotifier, AdminProductListState>(AdminProductListNotifier.new);

class AdminProductListNotifier extends Notifier<AdminProductListState> {
  static const int _pageSize = 20;

  @override
  AdminProductListState build() {
    _fetch(resetItems: true);
    return const AdminProductListState(loading: true);
  }

  AdminModerationApiService get _api => ref.read(adminModerationApiServiceProvider);

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
      final result = await _api.getProducts(search: state.search, page: nextPage, pageSize: _pageSize);
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
