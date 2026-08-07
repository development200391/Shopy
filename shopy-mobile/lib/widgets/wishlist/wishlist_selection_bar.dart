import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../cart/delete_confirm_sheet.dart';

/// Bar aksi bulk yang menggantikan [AppBottomNav] saat mode pilih aktif di
/// halaman Wishlist — hapus beberapa item sekaligus atau pindahkan ke keranjang.
class WishlistSelectionBar extends ConsumerWidget {
  const WishlistSelectionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCount = ref.watch(wishlistProvider.select((state) => state.selectedCount));

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
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                  onPressed: selectedCount == 0
                      ? null
                      : () async {
                          final confirmed = await showDeleteConfirmSheet(
                            context,
                            title: 'Hapus $selectedCount produk?',
                            message: 'Produk yang dipilih akan dihapus dari wishlist.',
                          );
                          if (confirmed == true) ref.read(wishlistProvider.notifier).removeSelected();
                        },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text('Hapus ($selectedCount)'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: selectedCount == 0
                      ? null
                      : () {
                          ref.read(wishlistProvider.notifier).moveSelectedToCart(ref.read(cartProvider.notifier));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Produk dipindahkan ke keranjang')),
                          );
                        },
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                  label: Text('+ Keranjang ($selectedCount)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
