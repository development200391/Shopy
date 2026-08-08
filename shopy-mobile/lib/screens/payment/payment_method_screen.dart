import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order/order_detail.dart';
import '../../models/payment/payment_method.dart';
import '../../providers/payment_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import 'payment_instruction_screen.dart';

const _methodGroups = [
  ('Transfer Bank', [PaymentMethod.bcaVa, PaymentMethod.bniVa]),
  ('E-Wallet', [PaymentMethod.goPay]),
  ('QRIS', [PaymentMethod.qris]),
];

/// Halaman Metode Pembayaran. Desain terpilih: **Bold & Colorful** (lihat
/// `UI Design - Checkout, Payment, Notifikasi/07_pembayaran_pilih_metode.png`).
///
/// Mockup juga menampilkan Transfer Mandiri, OVO, dan DANA — sengaja tidak
/// ditampilkan karena backend cuma dukung metode yang benar-benar terintegrasi
/// ke Midtrans Core API (lihat `PaymentMethod` di backend).
class PaymentMethodScreen extends ConsumerStatefulWidget {
  final OrderDetail order;

  const PaymentMethodScreen({super.key, required this.order});

  @override
  ConsumerState<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  PaymentMethod _selected = PaymentMethod.bcaVa;
  bool _submitting = false;

  Future<void> _pay() async {
    setState(() => _submitting = true);
    try {
      final payment = await ref
          .read(paymentApiServiceProvider)
          .createPayment(orderId: widget.order.id, method: _selected);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PaymentInstructionScreen(order: widget.order, payment: payment)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Metode Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Tagihan', style: TextStyle(color: AppColors.textSecondary)),
                Text(
                  formatRupiah(widget.order.totalAmount),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          for (final group in _methodGroups) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              group.$1.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final method in group.$2)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _MethodOption(
                  method: method,
                  selected: method == _selected,
                  onTap: () => setState(() => _selected = method),
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _pay,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Bayar ${formatRupiah(widget.order.totalAmount)}'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _MethodOption({required this.method, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(12)),
              child: Text(
                method.badge,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(method.label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: 2),
              ),
              child: selected
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
