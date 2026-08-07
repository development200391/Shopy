import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// State kosong halaman Wishlist.
class EmptyWishlistView extends StatelessWidget {
  final VoidCallback onExplore;

  const EmptyWishlistView({super.key, required this.onExplore});

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
              child: Icon(Icons.favorite_border, size: 56, color: AppColors.primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Belum Ada Favorit', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Simpan produk yang kamu suka di sini biar gampang dicari lagi nanti.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: onExplore, child: const Text('Jelajahi Produk')),
          ],
        ),
      ),
    );
  }
}
