import '../models/notification/app_notification.dart';

class NotificationHistoryState {
  final List<AppNotification> items;
  final int page;
  final int totalCount;
  final bool hasMore;
  final bool loading;
  final String? error;

  const NotificationHistoryState({
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.hasMore = false,
    this.loading = false,
    this.error,
  });

  bool get isEmpty => items.isEmpty;

  NotificationHistoryState copyWith({
    List<AppNotification>? items,
    int? page,
    int? totalCount,
    bool? hasMore,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationHistoryState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
