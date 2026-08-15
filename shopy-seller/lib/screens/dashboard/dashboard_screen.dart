import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dashboard/seller_dashboard.dart';
import '../../models/store/store_summary.dart';
import '../../providers/notification_provider.dart';
import '../../providers/seller_dashboard_provider.dart';
import '../../providers/store_settings_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import '../finance/withdrawal_screen.dart';
import '../notifications/notification_history_screen.dart';
import '../order/order_list_screen.dart';
import '../product/product_list_screen.dart';
import '../review/review_list_screen.dart';
import '../statistics/statistics_screen.dart';

/// Halaman **Beranda/Dashboard** — tab pertama bottom nav seller. Desain
/// terpilih: **Bold & Colorful** (lihat `design/assets/dashboard-seller-bold-colorful.png`).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(storeDetailProvider);
    final dashboardAsync = ref.watch(sellerDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(sellerDashboardProvider);
            ref.invalidate(unreadNotificationCountProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              storeAsync.when(
                loading: () => const SizedBox(height: 40),
                error: (_, _) => const SizedBox(height: 40),
                data: (store) => Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: store.logoUrl == null
                          ? null
                          : NetworkImage('${resolveApiBaseUrl()}${store.logoUrl}'),
                      child: store.logoUrl == null
                          ? const Icon(Icons.storefront_outlined, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (store.status == StoreStatus.active)
                            Row(
                              children: [
                                const Icon(Icons.check_circle, size: 12, color: AppColors.success),
                                const SizedBox(width: 2),
                                const Text(
                                  'Toko Terverifikasi',
                                  style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    _NotificationBell(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              dashboardAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Center(
                  child: Column(
                    children: [
                      const Text('Gagal memuat dashboard', style: TextStyle(color: AppColors.textSecondary)),
                      TextButton(
                        onPressed: () => ref.invalidate(sellerDashboardProvider),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
                data: (dashboard) => _DashboardBody(dashboard: dashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unread = unreadAsync.value ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()),
          ),
          icon: const Icon(Icons.notifications_outlined),
        ),
        if (unread > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final SellerDashboard dashboard;

  const _DashboardBody({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BalanceCard(dashboard: dashboard),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Ringkasan Hari Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatisticsScreen())),
              child: const Text('Lihat Statistik'),
            ),
          ],
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.5,
          children: [
            _StatCard(icon: Icons.bar_chart, iconColor: AppColors.primary, value: '${dashboard.newOrders}', label: 'Pesanan Baru'),
            _StatCard(icon: Icons.inventory_2_outlined, iconColor: Colors.blue, value: '${dashboard.productsSoldToday}', label: 'Produk Terjual'),
            _StatCard(icon: Icons.visibility_outlined, iconColor: AppColors.success, value: '${dashboard.storeVisitors}', label: 'Pengunjung Toko'),
            _StatCard(icon: Icons.payments_outlined, iconColor: AppColors.warning, value: formatRupiah(dashboard.incomeToday), label: 'Penghasilan'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Perlu Ditindaklanjuti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: AppSpacing.sm),
        _FollowUpRow(
          icon: Icons.assignment_outlined,
          iconColor: AppColors.primary,
          title: 'Pesanan baru menunggu konfirmasi',
          count: dashboard.needsFollowUp.newOrders,
          unit: 'pesanan',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const OrderListScreen(initialStatus: 'new'))),
        ),
        _FollowUpRow(
          icon: Icons.local_shipping_outlined,
          iconColor: Colors.blue,
          title: 'Siap dikirim, input resi',
          count: dashboard.needsFollowUp.readyToShip,
          unit: 'pesanan',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const OrderListScreen(initialStatus: 'processing'))),
        ),
        _FollowUpRow(
          icon: Icons.error_outline,
          iconColor: AppColors.warning,
          title: 'Stok produk menipis',
          count: dashboard.needsFollowUp.lowStockCount,
          unit: 'produk',
          onTap: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProductListScreen())),
        ),
        _FollowUpRow(
          icon: Icons.star_outline,
          iconColor: AppColors.success,
          title: 'Ulasan belum dibalas',
          count: dashboard.needsFollowUp.unrepliedReviews,
          unit: 'ulasan',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReviewListScreen(initialFilter: 'belum-dibalas')),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Sales7DaysCard(sales: dashboard.sales7Days),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final SellerDashboard dashboard;

  const _BalanceCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saldo Penjualan', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            formatRupiah(dashboard.availableBalance),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Saldo tertahan ${formatRupiah(dashboard.pendingBalance)}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WithdrawalScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
            label: const Text('Cairkan Dana'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.iconColor, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FollowUpRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final String unit;
  final VoidCallback onTap;

  const _FollowUpRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('$count $unit', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Sales7DaysCard extends StatelessWidget {
  final List<DailySales> sales;

  const _Sales7DaysCard({required this.sales});

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final total = sales.fold<int>(0, (sum, s) => sum + s.total);
    final maxValue = sales.map((s) => s.total).fold<int>(0, (m, v) => v > m ? v : m);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Penjualan 7 Hari Terakhir', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(formatRupiah(total), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 140,
            child: maxValue == 0
                ? const Center(
                    child: Text('Belum ada penjualan minggu ini.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxValue * 1.2,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= sales.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _dayLabels[sales[index].date.weekday - 1],
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < sales.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: sales[i].total.toDouble(),
                                color: AppColors.primary.withValues(alpha: i == sales.length - 1 ? 1 : 0.4),
                                width: 18,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
