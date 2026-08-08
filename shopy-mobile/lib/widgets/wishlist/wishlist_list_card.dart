import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/wishlist/wishlist_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import '../shared/placeholder_thumbnail.dart';

/// Kartu produk untuk mode list (baris horizontal) di halaman Wishlist —
/// alternatif layout dari grid, lengkap dengan tombol "+ Keranjang" langsung.
class WishlistListCard extends ConsumerWidget {
  final WishlistItem item;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const WishlistListCard({
    super.key,
    required this.item,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode) ...[
                Checkbox(value: selected, activeColor: AppColors.primary, onChanged: (_) => onTap()),
                const SizedBox(width: 4),
              ],
              const SizedBox(width: 72, height: 72, child: PlaceholderThumbnail()),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 13, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text('${item.rating}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatRupiah(item.price),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    if (!selectionMode) ...[
                      const SizedBox(height: AppSpacing.xs),
                      SizedBox(
                        height: 30,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await ref.read(cartProvider.notifier).addItem(productId: item.productId);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${item.name} ditambahkan ke keranjang')),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          },
                          icon: const Icon(Icons.shopping_cart_outlined, size: 14),
                          label: const Text('Keranjang', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!selectionMode)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => ref.read(wishlistProvider.notifier).removeItem(item.id),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.favorite, color: AppColors.error, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
