import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order/sub_order_status.dart';
import '../../models/order/sub_order_summary.dart';
import '../../providers/order_history_state.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/shared/app_bottom_nav.dart';
import '../../widgets/shared/placeholder_thumbnail.dart';
import '../cart/cart_screen.dart';
import '../home/home_screen.dart';
import '../wishlist/wishlist_screen.dart';
import 'order_detail_screen.dart';

const _tabs = [
  (label: 'Semua', status: null),
  (label: 'Diproses', status: SubOrderStatus.processing),
  (label: 'Dikirim', status: SubOrderStatus.shipped),
  (label: 'Selesai', status: SubOrderStatus.completed),
];

/// Halaman Riwayat Transaksi — 1 kartu per toko (`SubOrder`), sesuai
/// TASKSELLER.md Fase 4. Desain terpilih: **Bold & Colorful** (lihat
/// `UI Design - Checkout, Payment, Notifikasi/04_riwayat_transaksi_list.png`
/// & `05_riwayat_transaksi_kosong.png`).
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(orderHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final active = tab.status == history.statusFilter;
                  return ChoiceChip(
                    label: Text(tab.label),
                    selected: active,
                    onSelected: (_) => ref.read(orderHistoryProvider.notifier).setStatusFilter(tab.status),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: active ? Colors.white : AppColors.textPrimary),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.06),
                    side: BorderSide.none,
                  );
                },
              ),
            ),
          ),
          Expanded(child: _OrderHistoryBody(history: history)),
        ],
      ),
      bottomNavigationBar: AppBottomNav(currentTab: AppTab.profil, onTap: (tab) => _onTabTap(context, tab)),
    );
  }

  void _onTabTap(BuildContext context, AppTab tab) {
    switch (tab) {
      case AppTab.profil:
        return;
      case AppTab.home:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
        return;
      case AppTab.keranjang:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CartScreen()));
        return;
      case AppTab.wishlist:
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const WishlistScreen()));
        return;
      case AppTab.kategori:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Halaman ini belum tersedia.')));
        return;
    }
  }
}

class _OrderHistoryBody extends ConsumerWidget {
  final OrderHistoryState history;

  const _OrderHistoryBody({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history.loading && history.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (history.error != null && history.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat riwayat transaksi', style: TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => ref.read(orderHistoryProvider.notifier).reload(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (history.items.isEmpty) {
      return _EmptyOrderHistory(
        onStartShopping: () => Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen())),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: history.items.length + (history.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= history.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: history.loading
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: () => ref.read(orderHistoryProvider.notifier).loadMore(),
                      child: const Text('Muat Lebih Banyak'),
                    ),
            ),
          );
        }
        final order = history.items[index];
        return _OrderCard(
          order: order,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(subOrderId: order.id))),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final SubOrderSummary order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(order.storeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('#${order.subOrderNumber}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (var i = 0; i < order.previewImageUrls.length; i++)
                  Padding(
                    padding: EdgeInsets.only(right: i == order.previewImageUrls.length - 1 ? 0 : AppSpacing.sm),
                    child: const SizedBox(width: 56, height: 56, child: PlaceholderThumbnail()),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.itemCount} produk · ${formatRupiah(order.totalAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: const [
                    Text('Lihat Detail', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SubOrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SubOrderStatus.waitingPayment => AppColors.warning,
      SubOrderStatus.newOrder => AppColors.warning,
      SubOrderStatus.processing => AppColors.primary,
      SubOrderStatus.shipped => Colors.blue,
      SubOrderStatus.completed => AppColors.success,
      SubOrderStatus.cancelled => AppColors.error,
      SubOrderStatus.rejected => AppColors.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyOrderHistory extends StatelessWidget {
  final VoidCallback onStartShopping;

  const _EmptyOrderHistory({required this.onStartShopping});

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
              child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 56),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Belum Ada Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Pesananmu akan muncul di sini setelah kamu belanja.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStartShopping,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Mulai Belanja'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
