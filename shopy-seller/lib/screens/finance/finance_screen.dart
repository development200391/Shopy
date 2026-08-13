import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/finance/balance_transaction.dart';
import '../../models/finance/store_balance.dart';
import '../../providers/seller_finance_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import 'withdrawal_screen.dart';

const _tabs = [
  (label: 'Semua', type: null),
  (label: 'Pemasukan', type: 'income'),
  (label: 'Pencairan', type: 'withdrawal'),
];

/// Halaman **Keuangan** — desain terpilih: **Bold & Colorful**
/// (lihat `design/assets/keuangan-seller-bold-colorful.png`).
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  String? _type;

  void _refreshAll() {
    ref.invalidate(storeBalanceProvider);
    for (final tab in _tabs) {
      ref.invalidate(balanceTransactionsProvider(tab.type));
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(storeBalanceProvider);
    final transactionsAsync = ref.watch(balanceTransactionsProvider(_type));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Keuangan')),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            balanceAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              )),
              error: (error, _) => _ErrorState(onRetry: () => ref.invalidate(storeBalanceProvider)),
              data: (balance) => _BalanceCard(
                balance: balance,
                onWithdraw: () async {
                  final changed = await Navigator.of(
                    context,
                  ).push<bool>(MaterialPageRoute(builder: (_) => const WithdrawalScreen()));
                  if (changed == true) _refreshAll();
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            balanceAsync.maybeWhen(
              data: (balance) => _StatsRow(balance: balance),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mutasi Saldo', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Fitur unduh laporan belum tersedia.'))),
                  child: const Text('Unduh Laporan'),
                ),
              ],
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final active = tab.type == _type;
                  return ChoiceChip(
                    label: Text(tab.label),
                    selected: active,
                    onSelected: (_) => setState(() => _type = tab.type),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: active ? AppColors.onPrimary : AppColors.textPrimary),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    side: BorderSide.none,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            transactionsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              )),
              error: (error, _) =>
                  _ErrorState(onRetry: () => ref.invalidate(balanceTransactionsProvider(_type))),
              data: (transactions) => transactions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(child: Text('Belum ada mutasi di kategori ini.')),
                    )
                  : Column(
                      children: [
                        for (final tx in transactions) _TransactionTile(transaction: tx),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Gagal memuat data', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final StoreBalance balance;
  final VoidCallback onWithdraw;

  const _BalanceCard({required this.balance, required this.onWithdraw});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saldo Bisa Dicairkan', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            formatRupiah(balance.availableBalance),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Saldo tertahan ${formatRupiah(balance.pendingBalance)} (pesanan berjalan)',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onWithdraw,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
              icon: const Icon(Icons.account_balance_outlined),
              label: const Text('Cairkan Dana'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final StoreBalance balance;

  const _StatsRow({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(label: 'Penghasilan bulan ini', value: formatRupiah(balance.monthlyEarning)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(label: 'Komisi dipotong', value: formatRupiah(balance.monthlyCommission)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(label: 'Pesanan selesai', value: '${balance.completedOrderCountThisMonth} pesanan'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

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
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final BalanceTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final incoming = transaction.isIncoming;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
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
            decoration: BoxDecoration(
              color: (incoming ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              incoming ? Icons.arrow_downward : Icons.arrow_upward,
              color: incoming ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? transaction.type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(_formatDateTime(transaction.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${incoming ? '+' : '-'} ${formatRupiah(transaction.amount.abs())}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: incoming ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day ${months[local.month - 1]} ${local.year} - $hour:$minute';
  }
}
