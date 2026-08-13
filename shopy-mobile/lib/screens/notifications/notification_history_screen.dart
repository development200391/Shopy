import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification/app_notification.dart';
import '../../models/notification/notification_type.dart';
import '../../providers/notification_history_state.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../orders/order_history_screen.dart';

/// Halaman Riwayat Notifikasi. Desain terpilih: **Bold & Colorful** (lihat
/// `UI Design - Checkout, Payment, Notifikasi/11_riwayat_notifikasi_list.png`
/// & `12_riwayat_notifikasi_kosong.png`).
class NotificationHistoryScreen extends ConsumerWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(notificationHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (!history.isEmpty)
            TextButton(
              onPressed: () => ref.read(notificationHistoryProvider.notifier).markAllRead(),
              child: const Text('Tandai semua dibaca'),
            ),
        ],
      ),
      body: _NotificationBody(history: history),
    );
  }
}

class _NotificationBody extends ConsumerWidget {
  final NotificationHistoryState history;

  const _NotificationBody({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history.loading && history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (history.error != null && history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat notifikasi', style: TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => ref.read(notificationHistoryProvider.notifier).reload(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (history.isEmpty) {
      return const _EmptyNotifications();
    }

    final groups = _groupByDay(history.items);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              group.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          for (final notification in group.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _NotificationCard(
                notification: notification,
                onTap: () {
                  ref.read(notificationHistoryProvider.notifier).markRead(notification.id);
                  if (notification.orderId != null) {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                  }
                },
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (history.hasMore)
          Center(
            child: history.loading
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    onPressed: () => ref.read(notificationHistoryProvider.notifier).loadMore(),
                    child: const Text('Muat Lebih Banyak'),
                  ),
          ),
      ],
    );
  }

  List<_NotificationGroup> _groupByDay(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<AppNotification>>{};
    for (final item in items) {
      final local = item.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final label = day == today
          ? 'Hari Ini'
          : day == yesterday
          ? 'Kemarin'
          : '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
      groups.putIfAbsent(label, () => []).add(item);
    }

    return [for (final entry in groups.entries) _NotificationGroup(entry.key, entry.value)];
  }
}

class _NotificationGroup {
  final String label;
  final List<AppNotification> items;

  const _NotificationGroup(this.label, this.items);
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPromo = notification.type == NotificationType.promo;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isRead ? AppColors.divider : AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isPromo ? AppColors.secondary : AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(isPromo ? Icons.local_offer : Icons.shopping_bag, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _relativeTime(notification.createdAt),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime createdAt) {
    final local = createdAt.toLocal();
    final diff = DateTime.now().difference(local);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    if (diff.inDays == 1) return 'Kemarin, $hour.$minute';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}, $hour.$minute';
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none, color: AppColors.primary, size: 56),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Belum Ada Notifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Info promo & status pesananmu akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
