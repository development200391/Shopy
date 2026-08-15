import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/withdrawal/admin_withdrawal.dart';
import '../services/admin_withdrawal_api_service.dart';
import 'admin_withdrawal_list_state.dart';
import 'auth_provider.dart';

final adminWithdrawalApiServiceProvider = Provider<AdminWithdrawalApiService>((ref) {
  return AdminWithdrawalApiService(ref.watch(apiClientProvider));
});

final adminWithdrawalListProvider =
    NotifierProvider<AdminWithdrawalListNotifier, AdminWithdrawalListState>(AdminWithdrawalListNotifier.new);

class AdminWithdrawalListNotifier extends Notifier<AdminWithdrawalListState> {
  static const int _pageSize = 20;

  @override
  AdminWithdrawalListState build() {
    _fetch(resetItems: true);
    return const AdminWithdrawalListState(loading: true);
  }

  AdminWithdrawalApiService get _api => ref.read(adminWithdrawalApiServiceProvider);

  Future<void> setStatusFilter(AdminWithdrawalStatus? status) {
    state = status == null
        ? state.copyWith(clearStatusFilter: true)
        : state.copyWith(statusFilter: status);
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
      final result = await _api.getWithdrawals(
        status: state.statusFilter?.apiValue,
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
