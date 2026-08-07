import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Baris "Punya kode promo?" (belum ada voucher) atau chip voucher yang
/// sudah diterapkan (state "promo" di mockup). Kode contoh yang valid: HEMAT20.
class PromoCodeSection extends ConsumerWidget {
  const PromoCodeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    if (cart.hasPromo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          children: [
            const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${cart.promoCode} diterapkan',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => _openPromoDialog(context, ref),
              child: const Text('Ganti'),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _openPromoDialog(context, ref),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            const Icon(Icons.confirmation_number_outlined, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text('Punya kode promo?', style: TextStyle(color: AppColors.textSecondary)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _openPromoDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: ref.read(cartProvider).promoCode ?? '');
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Masukkan Kode Promo'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'Contoh: HEMAT20'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );

    if (code == null || code.trim().isEmpty) return;
    if (!context.mounted) return;

    final success = ref.read(cartProvider.notifier).applyPromoCode(code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Kode promo berhasil diterapkan' : 'Kode promo tidak valid'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }
}
