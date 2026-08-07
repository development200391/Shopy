import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import 'checkout_summary_sheet.dart';

/// Bar total + tombol Checkout yang nempel di bawah halaman Keranjang saat
/// ada barang. Menggantikan [AppBottomNav] selama ada isi, sama seperti di
/// mockup — begitu keranjang kosong, nav 5-tab yang tampil lagi.
class CartCheckoutBar extends ConsumerWidget {
  const CartCheckoutBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(
                      formatRupiah(cart.total),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: cart.selectedCount == 0 ? null : () => showCheckoutSummarySheet(context),
                child: Text('Checkout${cart.selectedCount > 0 ? ' (${cart.selectedCount})' : ''}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
