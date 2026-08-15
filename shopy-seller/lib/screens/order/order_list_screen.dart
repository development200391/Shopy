import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order/seller_order_summary.dart';
import '../../providers/seller_order_provider.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import 'order_detail_screen.dart';
import 'ship_order_screen.dart';

const _tabs = [
  (status: 'new', label: 'Baru'),
  (status: 'processing', label: 'Diproses'),
  (status: 'shipped', label: 'Dikirim'),
  (status: 'completed', label: 'Selesai'),
];

/// Halaman **Daftar Pesanan** — desain terpilih: **Bold & Colorful**
/// (lihat `design/assets/pesanan-list-seller-bold-colorful.png`).
class OrderListScreen extends ConsumerStatefulWidget {
  final String initialStatus;

  const OrderListScreen({super.key, this.initialStatus = 'new'});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  late String _status = widget.initialStatus;

  void _refreshAll() {
    for (final tab in _tabs) {
      ref.invalidate(sellerOrdersProvider(tab.status));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(sellerOrdersProvider(_status));

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                for (final tab in _tabs) ...[
                  _TabChip(
                    label: tab.label,
                    count: ref.watch(sellerOrdersProvider(tab.status)).value?.length,
                    selected: _status == tab.status,
                    onTap: () => setState(() => _status = tab.status),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  _ErrorState(onRetry: () => ref.invalidate(sellerOrdersProvider(_status))),
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(child: Text('Belum ada pesanan di kategori ini.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => _refreshAll(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) =>
                        _OrderCard(order: orders[index], onChanged: _refreshAll),
                  ),
                );
              },
            ),
          ),
        ],
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
          const Text('Gagal memuat pesanan', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({required this.label, this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(count == null ? label : '$label $count'),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.onPrimary : AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide.none,
    );
  }
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'NewOrder' => ('Baru', AppColors.primary),
      'Processing' => ('Diproses', Colors.blue),
      'Shipped' => ('Dikirim', Colors.indigo),
      'Completed' => ('Selesai', AppColors.success),
      'Rejected' => ('Ditolak', AppColors.error),
      'Cancelled' => ('Dibatalkan', AppColors.textSecondary),
      _ => (status, AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  final SellerOrderSummary order;
  final VoidCallback onChanged;

  const _OrderCard({required this.order, required this.onChanged});

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _busy = false;

  Future<void> _openDetail() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: widget.order.id)));
    widget.onChanged();
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      await ref.read(sellerOrderApiServiceProvider).accept(widget.order.id);
      widget.onChanged();
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak pesanan?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Alasan penolakan (mis. stok habis)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Tolak')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final reason = reasonController.text.trim();
      await ref
          .read(sellerOrderApiServiceProvider)
          .reject(widget.order.id, reason.isEmpty ? 'Stok tidak tersedia' : reason);
      widget.onChanged();
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ship() async {
    final shipped = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => ShipOrderScreen(orderId: widget.order.id)));
    if (shipped == true) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return GestureDetector(
      onTap: _openDetail,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                Expanded(
                  child: Text(
                    '#${order.subOrderNumber}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(order.buyerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(
                  _relativeTime(order.createdAt),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${order.itemCount} produk',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  'Total ${formatRupiah(order.totalAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (order.status == 'NewOrder' && order.autoCancelAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _Countdown(deadline: order.autoCancelAt!),
            ],
            if (order.status == 'NewOrder') ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _reject,
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : _accept,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                            )
                          : const Text('Proses Pesanan'),
                    ),
                  ),
                ],
              ),
            ] else if (order.status == 'Processing') ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _ship,
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Input Nomor Resi'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Countdown extends StatefulWidget {
  final DateTime deadline;

  const _Countdown({required this.deadline});

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deadline.difference(DateTime.now());
    final text = remaining.isNegative
        ? 'Menunggu diproses ulang otomatis'
        : 'Proses dalam ${_formatDuration(remaining)}';
    return Row(
      children: [
        const Icon(Icons.access_time, size: 14, color: AppColors.error),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }
}
