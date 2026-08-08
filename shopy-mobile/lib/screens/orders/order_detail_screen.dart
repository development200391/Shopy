import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order/order_detail.dart';
import '../../models/order/order_status.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/shared/placeholder_thumbnail.dart';

/// Halaman Detail Pesanan + tracking status. Desain terpilih: **Bold &
/// Colorful** (lihat
/// `UI Design - Checkout, Payment, Notifikasi/06_detail_pesanan_tracking.png`).
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gagal memuat pesanan', style: TextStyle(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (order) => _OrderDetailBody(order: order),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  final OrderDetail order;

  const _OrderDetailBody({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('#${order.orderNumber}', style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        _StatusBanner(order: order),
        const SizedBox(height: AppSpacing.lg),
        if (order.status != OrderStatus.cancelled) ...[
          const _SectionLabel('Lacak Pesanan'),
          const SizedBox(height: AppSpacing.sm),
          _TrackingTimeline(order: order),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
        ],
        const _SectionLabel('Produk'),
        const SizedBox(height: AppSpacing.sm),
        for (final item in order.items)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const SizedBox(width: 56, height: 56, child: PlaceholderThumbnail()),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantity}x ${formatRupiah(item.unitPrice)}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        const _SectionLabel('Alamat Pengiriman'),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${order.address.recipientName} · ${order.address.phoneNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                '${order.address.fullAddress}, ${order.address.city}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (order.note != null) ...[
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Catatan'),
          const SizedBox(height: AppSpacing.sm),
          Text(order.note!, style: const TextStyle(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: AppSpacing.md),
        const Divider(),
        _SummaryRow(label: 'Subtotal Produk', value: formatRupiah(order.subtotal)),
        _SummaryRow(label: 'Ongkos Kirim', value: formatRupiah(order.shippingCost)),
        _SummaryRow(label: 'Total Pembayaran', value: formatRupiah(order.totalAmount), bold: true),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur hubungi penjual belum tersedia.')),
                ),
                child: const Text('Hubungi Penjual'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur lacak paket belum tersedia.')),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Lacak Paket'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final OrderDetail order;

  const _StatusBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final (color, caption) = switch (order.status) {
      OrderStatus.pending => (AppColors.warning, 'Pesanan sedang menunggu diproses penjual.'),
      OrderStatus.processing => (AppColors.primary, 'Penjual sedang menyiapkan pesananmu.'),
      OrderStatus.shipped => (AppColors.primary, 'Estimasi tiba dalam 2-3 hari.'),
      OrderStatus.completed => (AppColors.success, 'Pesanan telah diterima. Terima kasih!'),
      OrderStatus.cancelled => (AppColors.error, 'Pesanan ini telah dibatalkan.'),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.status.label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(caption, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

const _trackingSteps = [
  (status: OrderStatus.pending, label: 'Pesanan Dibuat'),
  (status: OrderStatus.processing, label: 'Diproses Penjual'),
  (status: OrderStatus.shipped, label: 'Dikirim'),
  (status: OrderStatus.completed, label: 'Pesanan Diterima'),
];

class _TrackingTimeline extends StatelessWidget {
  final OrderDetail order;

  const _TrackingTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _trackingSteps.indexWhere((s) => s.status == order.status);

    return Column(
      children: [
        for (var i = 0; i < _trackingSteps.length; i++)
          _TimelineStep(
            label: _trackingSteps[i].label,
            changedAt: order.statusHistory.where((h) => h.status == _trackingSteps[i].status).firstOrNull?.changedAt,
            reached: i <= currentIndex,
            active: i == currentIndex,
            isLast: i == _trackingSteps.length - 1,
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final DateTime? changedAt;
  final bool reached;
  final bool active;
  final bool isLast;

  const _TimelineStep({
    required this.label,
    required this.changedAt,
    required this.reached,
    required this.active,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = reached ? AppColors.primary : AppColors.divider;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: active ? 20 : 14,
                height: active ? 20 : 14,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: reached ? AppColors.primary : Colors.white,
                  border: Border.all(color: color, width: 2),
                ),
                child: active
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      )
                    : null,
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: color)),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: reached ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    changedAt != null ? _formatDateTime(changedAt!) : 'Menunggu',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day ${months[local.month - 1]} ${local.year}, $hour.$minute';
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, fontSize: bold ? 16 : 14),
          ),
        ],
      ),
    );
  }
}
