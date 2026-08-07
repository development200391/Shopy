import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// State kosong halaman Keranjang.
class EmptyCartView extends StatelessWidget {
  final VoidCallback onStartShopping;

  const EmptyCartView({super.key, required this.onStartShopping});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
              child: Icon(Icons.shopping_bag_outlined, size: 56, color: AppColors.primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Keranjangmu Masih Kosong', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Yuk, mulai belanja dan temukan produk favoritmu di Shopy.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: onStartShopping, child: const Text('Mulai Belanja')),
          ],
        ),
      ),
    );
  }
}
