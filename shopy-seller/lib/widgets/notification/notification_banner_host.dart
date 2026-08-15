import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification_provider.dart';
import '../../screens/notifications/notification_history_screen.dart';
import '../../theme/app_spacing.dart';
import 'in_app_notification_banner.dart';
import 'notification_type_style.dart';

/// Membungkus seluruh app (lihat `main.dart`) supaya banner notifikasi
/// foreground bisa muncul di atas halaman mana pun yang lagi aktif.
class NotificationBannerHost extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationBannerHost({super.key, required this.child});

  @override
  ConsumerState<NotificationBannerHost> createState() => _NotificationBannerHostState();
}

class _NotificationBannerHostState extends ConsumerState<NotificationBannerHost> {
  StreamSubscription<RemoteMessage>? _sub;
  RemoteMessage? _current;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    final service = ref.read(pushNotificationServiceProvider);
    _sub = service.onForegroundMessage.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    if (!mounted) return;
    setState(() => _current = message);

    ref.invalidate(unreadNotificationCountProvider);
    ref.read(notificationHistoryProvider.notifier).reload();

    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    setState(() => _current = null);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = _current;

    return Stack(
      children: [
        widget.child,
        if (message != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: SafeArea(
              bottom: false,
              child: Builder(
                builder: (context) {
                  final (icon, color) = notificationTypeStyleFromApiValue(message.data['type']);
                  return InAppNotificationBanner(
                    title: message.notification?.title ?? 'Shopy Seller',
                    body: message.notification?.body ?? '',
                    icon: icon,
                    iconColor: color,
                    onDismiss: _dismiss,
                    onTap: () {
                      _dismiss();
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()));
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
