import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order/order_detail.dart';
import '../../models/payment/payment.dart';
import '../../models/payment/payment_method.dart';
import '../../models/payment/payment_status.dart';
import '../../providers/payment_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import 'payment_success_screen.dart';

/// Halaman "Selesaikan Pembayaran" — instruksi VA / QR + countdown. Desain
/// terpilih: **Bold & Colorful** (lihat
/// `UI Design - Checkout, Payment, Notifikasi/08_pembayaran_instruksi_va.png`).
class PaymentInstructionScreen extends ConsumerStatefulWidget {
  final OrderDetail order;
  final Payment payment;

  const PaymentInstructionScreen({super.key, required this.order, required this.payment});

  @override
  ConsumerState<PaymentInstructionScreen> createState() => _PaymentInstructionScreenState();
}

class _PaymentInstructionScreenState extends ConsumerState<PaymentInstructionScreen> {
  late Payment _payment = widget.payment;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final expiresAt = _payment.expiresAt;
    if (expiresAt == null) return;
    final remaining = expiresAt.difference(DateTime.now());
    setState(() => _remaining = remaining.isNegative ? Duration.zero : remaining);
  }

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    try {
      final updated = await ref.read(paymentApiServiceProvider).refreshLatestPayment(widget.order.id);
      if (!mounted) return;
      setState(() {
        _payment = updated;
        _checking = false;
      });

      if (updated.status == PaymentStatus.settled) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PaymentSuccessScreen(order: widget.order, payment: updated)),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status pembayaran: ${updated.status.label}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVa = _payment.method == PaymentMethod.bcaVa || _payment.method == PaymentMethod.bniVa;
    final expired = _payment.expiresAt != null && _remaining == Duration.zero;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Selesaikan Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (_payment.expiresAt != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: expired ? AppColors.textSecondary : AppColors.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    expired ? 'Waktu pembayaran habis' : 'Selesaikan sebelum',
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (!expired)
                    Text(
                      _formatDuration(_remaining),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          if (isVa) _VirtualAccountCard(payment: _payment) else _QrCard(payment: _payment),
          const SizedBox(height: AppSpacing.lg),
          const Text('CARA PEMBAYARAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          for (final (index, step) in _instructionsFor(_payment.method).indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(step, style: const TextStyle(color: AppColors.textSecondary))),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _checking ? null : _checkStatus,
              child: _checking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Cek Status Pembayaran'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  List<String> _instructionsFor(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.bcaVa || PaymentMethod.bniVa => [
          'Buka aplikasi mobile banking atau ATM ${method == PaymentMethod.bcaVa ? 'BCA' : 'BNI'}.',
          'Pilih menu Transfer > Virtual Account.',
          'Masukkan nomor Virtual Account di atas.',
          'Periksa detail pembayaran, lalu konfirmasi.',
        ],
      PaymentMethod.goPay => [
          'Buka aplikasi Gojek, pilih GoPay.',
          'Scan kode QR di atas.',
          'Periksa detail pembayaran, lalu konfirmasi di aplikasi.',
        ],
      PaymentMethod.qris => [
          'Buka aplikasi e-wallet atau m-banking favoritmu yang mendukung QRIS.',
          'Pilih menu Scan/Bayar QR.',
          'Scan kode QR di atas, lalu konfirmasi pembayaran.',
        ],
    };
  }
}

class _VirtualAccountCard extends StatelessWidget {
  final Payment payment;

  const _VirtualAccountCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  payment.method.badge,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Virtual Account ${payment.method.badge}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Nomor Virtual Account', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _groupDigits(payment.virtualAccountNumber ?? '-'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: payment.virtualAccountNumber ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor VA disalin')),
                  );
                },
                child: const Text('Salin'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('Total Pembayaran', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(
            formatRupiah(payment.amount),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  String _groupDigits(String number) {
    final buffer = StringBuffer();
    for (var i = 0; i < number.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(number[i]);
    }
    return buffer.toString();
  }
}

class _QrCard extends StatelessWidget {
  final Payment payment;

  const _QrCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(payment.method.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSpacing.md),
          if (payment.qrCodeUrl != null)
            Image.network(payment.qrCodeUrl!, width: 220, height: 220)
          else
            const SizedBox(
              width: 220,
              height: 220,
              child: Center(child: Text('QR tidak tersedia', style: TextStyle(color: AppColors.textSecondary))),
            ),
          const SizedBox(height: AppSpacing.md),
          const Text('Total Pembayaran', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(
            formatRupiah(payment.amount),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
