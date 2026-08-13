import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order/seller_order_detail.dart';
import '../../providers/seller_chat_provider.dart';
import '../../providers/seller_order_provider.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import '../chat/chat_room_screen.dart';
import 'ship_order_screen.dart';

/// Halaman **Detail Pesanan** — desain terpilih: **Bold & Colorful**
/// (lihat `design/assets/pesanan-detail-seller-bold-colorful.png`).
class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _busy = false;
  bool _changed = false;

  void _notAvailableYet() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fitur chat belum tersedia.')));
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      await ref.read(sellerOrderApiServiceProvider).accept(widget.orderId);
      _changed = true;
      ref.invalidate(sellerOrderDetailProvider(widget.orderId));
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
          .reject(widget.orderId, reason.isEmpty ? 'Stok tidak tersedia' : reason);
      _changed = true;
      ref.invalidate(sellerOrderDetailProvider(widget.orderId));
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
    ).push<bool>(MaterialPageRoute(builder: (_) => ShipOrderScreen(orderId: widget.orderId)));
    if (shipped == true) {
      _changed = true;
      ref.invalidate(sellerOrderDetailProvider(widget.orderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(sellerOrderDetailProvider(widget.orderId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: detailAsync.when(
            data: (order) => Text('#${order.subOrderNumber}', style: const TextStyle(fontSize: 14)),
            loading: () => const Text(''),
            error: (_, _) => const Text(''),
          ),
          titleSpacing: 0,
        ),
        body: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              _ErrorState(onRetry: () => ref.invalidate(sellerOrderDetailProvider(widget.orderId))),
          data: (order) => _Body(order: order),
        ),
        bottomNavigationBar: detailAsync.maybeWhen(
          data: (order) => _BottomActions(
            order: order,
            busy: _busy,
            onAccept: _accept,
            onReject: _reject,
            onShip: _ship,
            onNotAvailable: _notAvailableYet,
          ),
          orElse: () => null,
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
          const Text('Gagal memuat pesanan', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final SellerOrderDetail order;

  const _Body({required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusBanner(order: order),
          const SizedBox(height: AppSpacing.md),
          _BuyerCard(order: order),
          const SizedBox(height: AppSpacing.md),
          _AddressCard(order: order),
          const SizedBox(height: AppSpacing.md),
          _ProductsCard(order: order),
          const SizedBox(height: AppSpacing.md),
          _PaymentCard(order: order),
          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _NoteBox(note: order.note!),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final SellerOrderDetail order;

  const _StatusBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle, color) = switch (order.status) {
      'NewOrder' => (
        Icons.notifications_active_outlined,
        'Pesanan Baru',
        'Konfirmasi sebelum otomatis dibatalkan',
        AppColors.primary,
      ),
      'Processing' => (
        Icons.inventory_2_outlined,
        'Sedang Diproses',
        'Siapkan barang lalu input nomor resi',
        Colors.blue,
      ),
      'Shipped' => (
        Icons.local_shipping_outlined,
        'Sedang Dikirim',
        order.trackingNumber == null ? 'Menunggu diterima pembeli' : 'Resi: ${order.trackingNumber}',
        Colors.indigo,
      ),
      'Completed' => (Icons.check_circle_outline, 'Pesanan Selesai', 'Dana sudah masuk saldo', AppColors.success),
      'Rejected' => (
        Icons.cancel_outlined,
        'Pesanan Ditolak',
        order.cancelReason ?? 'Ditolak oleh toko',
        AppColors.error,
      ),
      _ => (Icons.info_outline, order.status, '', AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyerCard extends ConsumerWidget {
  final SellerOrderDetail order;

  const _BuyerCard({required this.order});

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    try {
      final room = await ref.read(sellerChatApiServiceProvider).findRoomByBuyer(order.buyer.userId);
      if (!context.mounted) return;
      if (room == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pembeli ini belum pernah memulai percakapan.')));
        return;
      }
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatRoomScreen(room: room)));
    } on SellerException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.person_outline, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.buyer.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Bergabung ${order.buyer.joinedYear} - ${order.buyer.orderCountAtThisStore} pesanan',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _openChat(context, ref),
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Chat'),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final SellerOrderDetail order;

  const _AddressCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final courierLabel = order.courierCode == null
        ? null
        : '${order.courierCode} ${order.courierService ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
              SizedBox(width: 4),
              Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${order.address.recipientName} - ${order.address.phoneNumber}'),
          const SizedBox(height: 2),
          Text(
            '${order.address.fullAddress}, ${order.address.city}, ${order.address.province} ${order.address.postalCode}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  courierLabel == null
                      ? 'Kurir dipilih saat kirim - ${formatRupiah(order.shippingCost)}'
                      : '$courierLabel - ${formatRupiah(order.shippingCost)}',
                ),
              ),
            ],
          ),
          if (order.trackingNumber != null) ...[
            const SizedBox(height: 4),
            Text('Resi: ${order.trackingNumber}', style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _ProductsCard extends StatelessWidget {
  final SellerOrderDetail order;

  const _ProductsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Produk Dipesan', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: const Icon(Icons.image_outlined, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${item.quantity} x ${formatRupiah(item.unitPrice)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(formatRupiah(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final SellerOrderDetail order;

  const _PaymentCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          _row('Subtotal produk', formatRupiah(order.subtotal)),
          _row('Ongkos kirim', formatRupiah(order.shippingCost)),
          _row('Total dibayar pembeli', formatRupiah(order.totalAmount), bold: true),
          _row('Komisi Shopy', '- ${formatRupiah(order.commissionAmount)}', color: AppColors.error),
          const Divider(height: AppSpacing.lg),
          _row(
            'Estimasi masuk saldo',
            formatRupiah(order.sellerEarning),
            bold: true,
            color: AppColors.success,
            large: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: large ? 18 : 14,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String note;

  const _NoteBox({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Catatan pembeli', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(note),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final SellerOrderDetail order;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onShip;
  final VoidCallback onNotAvailable;

  const _BottomActions({
    required this.order,
    required this.busy,
    required this.onAccept,
    required this.onReject,
    required this.onShip,
    required this.onNotAvailable,
  });

  @override
  Widget build(BuildContext context) {
    if (order.status == 'NewOrder') {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Tolak Pesanan'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: busy ? null : onAccept,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: busy
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
        ),
      );
    }

    if (order.status == 'Processing') {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ElevatedButton.icon(
            onPressed: onShip,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Input Nomor Resi'),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
