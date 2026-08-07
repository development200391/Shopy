import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';

/// Bottom sheet ringkasan belanja sebelum lanjut checkout (state
/// "checkout_summary" di mockup). Tombol "Lanjut ke Checkout" belum
/// terhubung ke alur nyata karena halaman Checkout (Fase 4) belum dikerjakan.
void showCheckoutSummarySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) {
      return Consumer(
        builder: (consumerContext, ref, _) {
          final cart = ref.watch(cartProvider);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              MediaQuery.of(consumerContext).viewInsets.bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                Text('Ringkasan Belanja', style: Theme.of(consumerContext).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                Text('Kirim ke', style: Theme.of(consumerContext).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ramdan · Rumah', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Jl. Melati No. 12, Bandung', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SummaryRow(label: 'Subtotal Produk', value: formatRupiah(cart.subtotal)),
                _SummaryRow(label: 'Ongkos Kirim', value: formatRupiah(cart.shippingCost)),
                if (cart.hasPromo)
                  _SummaryRow(
                    label: 'Diskon Voucher',
                    value: '-${formatRupiah(cart.promoDiscount)}',
                    valueColor: AppColors.primary,
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(),
                ),
                _SummaryRow(label: 'Total Pembayaran', value: formatRupiah(cart.total), bold: true),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(consumerContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Halaman Checkout belum tersedia (Fase 4 belum dikerjakan).'),
                        ),
                      );
                    },
                    child: const Text('Lanjut ke Checkout'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: valueColor ?? (bold ? AppColors.textPrimary : AppColors.textSecondary),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style.copyWith(color: bold ? AppColors.textPrimary : AppColors.textSecondary)),
          Text(value, style: style.copyWith(color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
