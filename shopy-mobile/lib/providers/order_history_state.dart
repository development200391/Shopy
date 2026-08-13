import '../models/order/sub_order_status.dart';
import '../models/order/sub_order_summary.dart';

class OrderHistoryState {
  final SubOrderStatus? statusFilter;
  final List<SubOrderSummary> items;
  final int page;
  final int totalCount;
  final bool hasMore;
  final bool loading;
  final String? error;

  const OrderHistoryState({
    this.statusFilter,
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.hasMore = false,
    this.loading = false,
    this.error,
  });

  OrderHistoryState copyWith({
    SubOrderStatus? statusFilter,
    bool clearStatusFilter = false,
    List<SubOrderSummary>? items,
    int? page,
    int? totalCount,
    bool? hasMore,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return OrderHistoryState(
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      items: items ?? this.items,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
