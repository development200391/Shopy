import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/wishlist/wishlist_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../shared/placeholder_thumbnail.dart';

/// Kartu produk untuk mode grid (2 kolom) di halaman Wishlist.
class WishlistGridCard extends ConsumerWidget {
  final WishlistItem item;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const WishlistGridCard({
    super.key,
    required this.item,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(child: PlaceholderThumbnail()),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: selectionMode
                        ? _SelectionDot(selected: selected)
                        : _RemoveHeartButton(item: item),
                  ),
                  if (!selectionMode)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: _QuickAddButton(item: item),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              formatRupiah(item.price),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, size: 13, color: Colors.amber),
                const SizedBox(width: 2),
                Text('${item.rating}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  final bool selected;

  const _SelectionDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: 2),
      ),
      child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
    );
  }
}

class _RemoveHeartButton extends ConsumerWidget {
  final WishlistItem item;

  const _RemoveHeartButton({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => ref.read(wishlistProvider.notifier).removeItem(item.id),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Icon(Icons.favorite, color: AppColors.error, size: 16),
      ),
    );
  }
}

class _QuickAddButton extends ConsumerWidget {
  final WishlistItem item;

  const _QuickAddButton({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        ref
            .read(cartProvider.notifier)
            .addItem(
              productId: item.productId,
              name: item.name,
              variant: item.variant.isEmpty ? '-' : item.variant,
              price: item.price,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} ditambahkan ke keranjang')),
        );
      },
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: const Icon(Icons.add, color: Colors.white, size: 18),
      ),
    );
  }
}
