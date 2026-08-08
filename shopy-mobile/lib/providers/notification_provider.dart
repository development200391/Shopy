import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/device_token_api_service.dart';
import '../services/notification_api_service.dart';
import '../services/push_notification_service.dart';
import 'auth_provider.dart';
import 'notification_history_state.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService(ref.watch(apiClientProvider));
});

final deviceTokenApiServiceProvider = Provider<DeviceTokenApiService>((ref) {
  return DeviceTokenApiService(ref.watch(apiClientProvider));
});

/// Singleton — dibuat sekali per sesi app, `initialize()` dipanggil begitu
/// user login (lihat `HomeScreen`), stream-nya didengarkan di
/// `NotificationBannerHost` yang membungkus seluruh app (lihat `main.dart`).
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(ref.watch(deviceTokenApiServiceProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Jumlah notifikasi belum dibaca — dipakai buat badge ikon lonceng di Home.
/// Di-invalidate manual (bukan auto-refresh) setiap kali ada notifikasi baru
/// (banner in-app muncul) atau setelah tandai dibaca.
final unreadNotificationCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationApiServiceProvider).getUnreadCount();
});

final notificationHistoryProvider =
    NotifierProvider<NotificationHistoryNotifier, NotificationHistoryState>(NotificationHistoryNotifier.new);

class NotificationHistoryNotifier extends Notifier<NotificationHistoryState> {
  static const int _pageSize = 20;

  @override
  NotificationHistoryState build() {
    _fetch(resetItems: true);
    return const NotificationHistoryState(loading: true);
  }

  NotificationApiService get _api => ref.read(notificationApiServiceProvider);

  Future<void> reload() => _fetch(resetItems: true);

  Future<void> loadMore() {
    if (state.loading || !state.hasMore) return Future.value();
    return _fetch(resetItems: false);
  }

  Future<void> markRead(String id) async {
    final target = state.items.where((n) => n.id == id).firstOrNull;
    if (target == null || target.isRead) return;

    state = state.copyWith(items: [for (final n in state.items) if (n.id == id) n.copyWith(isRead: true) else n]);
    try {
      await _api.markRead(id);
    } catch (_) {
      // Biarkan state optimistic — reload manual (pull-to-refresh) akan konsisten lagi.
    }
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> markAllRead() async {
    state = state.copyWith(items: [for (final n in state.items) n.copyWith(isRead: true)]);
    try {
      await _api.markAllRead();
    } catch (_) {
      // Sama seperti markRead.
    }
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> _fetch({required bool resetItems}) async {
    final nextPage = resetItems ? 1 : state.page + 1;
    state = state.copyWith(loading: true, clearError: true);

    try {
      final result = await _api.getNotifications(page: nextPage, pageSize: _pageSize);
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
