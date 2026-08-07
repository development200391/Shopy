import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Bottom sheet konfirmasi hapus produk dari keranjang/wishlist.
/// Return `true` kalau user menekan "Ya, Hapus", `false`/`null` kalau batal.
Future<bool?> showDeleteConfirmSheet(
  BuildContext context, {
  String title = 'Hapus produk ini?',
  String message = 'Produk akan dihapus dari keranjangmu.',
}) {
  return showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(3)),
            ),
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    child: const Text('Ya, Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
