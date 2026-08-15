import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store/admin_store.dart';
import '../services/admin_store_api_service.dart';
import 'admin_store_list_state.dart';
import 'auth_provider.dart';

final adminStoreApiServiceProvider = Provider<AdminStoreApiService>((ref) {
  return AdminStoreApiService(ref.watch(apiClientProvider));
});

final adminStoreListProvider =
    NotifierProvider<AdminStoreListNotifier, AdminStoreListState>(AdminStoreListNotifier.new);

class AdminStoreListNotifier extends Notifier<AdminStoreListState> {
  static const int _pageSize = 20;

  @override
  AdminStoreListState build() {
    _fetch(resetItems: true);
    return const AdminStoreListState(loading: true);
  }

  AdminStoreApiService get _api => ref.read(adminStoreApiServiceProvider);

  Future<void> setStatusFilter(AdminStoreStatus? status) {
    state = status == null
        ? state.copyWith(clearStatusFilter: true)
        : state.copyWith(statusFilter: status);
    return _fetch(resetItems: true);
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
      final result = await _api.getStores(
        status: state.statusFilter?.apiValue,
        q: state.search,
        page: nextPage,
        pageSize: _pageSize,
      );
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

final adminStoreDetailProvider = FutureProvider.autoDispose.family<AdminStoreDetail, String>((ref, id) {
  return ref.watch(adminStoreApiServiceProvider).getStore(id);
});
