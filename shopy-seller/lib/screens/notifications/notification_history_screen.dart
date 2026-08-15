import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification/app_notification.dart';
import '../../models/notification/notification_type.dart';
import '../../providers/notification_history_state.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/notification/notification_type_style.dart';

/// Halaman Riwayat Notifikasi seller. Desain terpilih: **Bold & Colorful**
/// (lihat `design/assets/notifikasi-seller-bold-colorful.png`).
///
/// Filter kategori disederhanakan jadi 3 chip (Semua/Pesanan/Keuangan) sesuai
/// mockup — `Pesanan` = [NotificationType.newOrder], `Keuangan` =
/// [NotificationType.paymentReceived] + [NotificationType.withdrawal]. Jenis
/// lain (LowStock/NewReview/NewChat/VoucherQuota) cuma tampil di "Semua",
/// tidak match chip manapun — deviasi kecil didokumentasikan di TASKSELLER.md.
class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  ConsumerState<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

const _pesananTypes = {NotificationType.newOrder};
const _keuanganTypes = {NotificationType.paymentReceived, NotificationType.withdrawal};

class _NotificationHistoryScreenState extends ConsumerState<NotificationHistoryScreen> {
  String _filter = 'semua';

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(notificationHistoryProvider);
    final filtered = switch (_filter) {
      'pesanan' => history.items.where((n) => _pesananTypes.contains(n.type)).toList(),
      'keuangan' => history.items.where((n) => _keuanganTypes.contains(n.type)).toList(),
      _ => history.items,
    };

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'Semua', value: 'semua', selected: _filter, onSelected: _setFilter),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Pesanan', value: 'pesanan', selected: _filter, onSelected: _setFilter),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Keuangan', value: 'keuangan', selected: _filter, onSelected: _setFilter),
                ],
              ),
            ),
          ),
          Expanded(child: _NotificationBody(history: history, items: filtered)),
        ],
      ),
    );
  }

  void _setFilter(String value) => setState(() => _filter = value);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterChip({required this.label, required this.value, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => onSelected(value),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: active ? Colors.white : AppColors.textPrimary),
      backgroundColor: AppColors.primary.withValues(alpha: 0.06),
      side: BorderSide.none,
    );
  }
}

class _NotificationBody extends ConsumerWidget {
  final NotificationHistoryState history;
  final List<AppNotification> items;

  const _NotificationBody({required this.history, required this.items});

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

    if (items.isEmpty) {
      return const _EmptyNotifications();
    }

    final groups = _groupByDay(items);

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
                onTap: () => ref.read(notificationHistoryProvider.notifier).markRead(notification.id),
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
    final (icon, color) = notificationTypeStyle(notification.type);

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
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white, size: 20),
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
              'Info pesanan, ulasan, dan keuangan tokomu akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
