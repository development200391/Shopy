import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dashboard/seller_dashboard.dart';
import '../../models/dashboard/seller_statistics.dart';
import '../../providers/seller_dashboard_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';

const _periods = [
  (value: '7d', label: '7 Hari'),
  (value: '30d', label: '30 Hari'),
  (value: '90d', label: '90 Hari'),
];

const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Halaman **Statistik Penjualan** — desain terpilih: **Bold & Colorful**
/// (lihat `design/assets/statistik-seller-bold-colorful.png`).
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _period = '7d';

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(sellerStatisticsProvider(_period));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Statistik Penjualan')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _periods.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final period = _periods[index];
                final active = period.value == _period;
                return ChoiceChip(
                  label: Text(period.label),
                  selected: active,
                  onSelected: (_) => setState(() => _period = period.value),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: active ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.06),
                  side: BorderSide.none,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          statsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Center(
              child: Column(
                children: [
                  const Text('Gagal memuat statistik', style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => ref.invalidate(sellerStatisticsProvider(_period)),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
            data: (stats) => _StatisticsBody(stats: stats),
          ),
        ],
      ),
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  final SellerStatistics stats;

  const _StatisticsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.6,
          children: [
            _MetricCard(icon: Icons.payments_outlined, label: 'Omzet', value: formatRupiah(stats.omzet.value.round()), metric: stats.omzet),
            _MetricCard(icon: Icons.receipt_long_outlined, label: 'Pesanan', value: '${stats.orderCount.value.round()}', metric: stats.orderCount),
            _MetricCard(icon: Icons.inventory_2_outlined, label: 'Produk Terjual', value: '${stats.productsSold.value.round()}', metric: stats.productsSold),
            _MetricCard(icon: Icons.bar_chart, label: 'Rata-rata Order', value: formatRupiah(stats.averageOrder.value.round()), metric: stats.averageOrder),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _DailyOmzetCard(dailySeries: stats.dailySeries),
        const SizedBox(height: AppSpacing.md),
        const Text('Produk Terlaris', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: AppSpacing.sm),
        if (stats.topProducts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text('Belum ada produk terjual di periode ini.', style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          for (var i = 0; i < stats.topProducts.length; i++) _TopProductRow(rank: i + 1, product: stats.topProducts[i]),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final StatisticsMetric metric;

  const _MetricCard({required this.icon, required this.label, required this.value, required this.metric});

  @override
  Widget build(BuildContext context) {
    final positive = metric.deltaPercent >= 0;
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
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
          Row(
            children: [
              Icon(positive ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: positive ? AppColors.success : AppColors.error),
              const SizedBox(width: 2),
              Text(
                '${metric.deltaPercent.abs().toStringAsFixed(0)}% vs periode lalu',
                style: TextStyle(color: positive ? AppColors.success : AppColors.error, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyOmzetCard extends StatelessWidget {
  final List<DailySales> dailySeries;

  const _DailyOmzetCard({required this.dailySeries});

  @override
  Widget build(BuildContext context) {
    final maxValue = dailySeries.map((s) => s.total).fold<int>(0, (m, v) => v > m ? v : m);
    final peakIndex = dailySeries.isEmpty
        ? -1
        : dailySeries.indexWhere((s) => s.total == maxValue);

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
              const Text('Omzet Harian', style: TextStyle(fontWeight: FontWeight.bold)),
              if (peakIndex >= 0)
                Text(
                  'Puncak: ${_dayLabels[dailySeries[peakIndex].date.weekday - 1]}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: maxValue == 0
                ? const Center(
                    child: Text('Belum ada omzet di periode ini.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxValue * 1.3,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: dailySeries.length <= 14,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= dailySeries.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _dayLabels[dailySeries[index].date.weekday - 1],
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < dailySeries.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: dailySeries[i].total.toDouble(),
                                color: i == peakIndex ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
                                width: dailySeries.length > 30 ? 3 : 18,
                                borderRadius: BorderRadius.circular(4),
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

class _TopProductRow extends StatelessWidget {
  final int rank;
  final TopProduct product;

  const _TopProductRow({required this.rank, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: rank == 1 ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
            child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 40,
              height: 40,
              child: product.imageUrl == null
                  ? Container(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 18),
                    )
                  : Image.network('${resolveApiBaseUrl()}${product.imageUrl}', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${product.quantitySold} terjual', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(formatRupiah(product.revenue), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
