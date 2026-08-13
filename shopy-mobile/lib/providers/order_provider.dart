import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order/sub_order_detail.dart';
import '../models/order/sub_order_status.dart';
import '../services/order_api_service.dart';
import 'auth_provider.dart';
import 'order_history_state.dart';

final orderApiServiceProvider = Provider<OrderApiService>((ref) {
  return OrderApiService(ref.watch(apiClientProvider));
});

/// Riverpod otomatis retry provider yang error — dimatikan karena halaman
/// Detail Pesanan sudah punya tombol "Coba lagi" manual sendiri.
Duration? _noRetry(int retryCount, Object error) => null;

final subOrderDetailProvider = FutureProvider.family<SubOrderDetail, String>((ref, id) {
  return ref.watch(orderApiServiceProvider).getSubOrderDetail(id);
}, retry: _noRetry);

final orderHistoryProvider = NotifierProvider<OrderHistoryNotifier, OrderHistoryState>(
  OrderHistoryNotifier.new,
);

class OrderHistoryNotifier extends Notifier<OrderHistoryState> {
  static const int _pageSize = 20;

  @override
  OrderHistoryState build() {
    _fetch(resetItems: true);
    return const OrderHistoryState(loading: true);
  }

  OrderApiService get _api => ref.read(orderApiServiceProvider);

  Future<void> setStatusFilter(SubOrderStatus? status) {
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
      final result = await _api.getSubOrders(status: state.statusFilter, page: nextPage, pageSize: _pageSize);
      state = state.copyWith(
        items: resetItems ? result.items : [...state.items, ...result.items],
        page: result.page,
        totalCount: result.totalCount,
        hasMore: result.hasMore,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
