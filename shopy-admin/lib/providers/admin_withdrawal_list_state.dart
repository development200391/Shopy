import '../models/withdrawal/admin_withdrawal.dart';

class AdminWithdrawalListState {
  final AdminWithdrawalStatus? statusFilter;
  final List<AdminWithdrawalListItem> items;
  final int page;
  final int totalCount;
  final bool hasMore;
  final bool loading;
  final String? error;

  const AdminWithdrawalListState({
    this.statusFilter,
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.hasMore = false,
    this.loading = false,
    this.error,
  });

  AdminWithdrawalListState copyWith({
    AdminWithdrawalStatus? statusFilter,
    bool clearStatusFilter = false,
    List<AdminWithdrawalListItem>? items,
    int? page,
    int? totalCount,
    bool? hasMore,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AdminWithdrawalListState(
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
