import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/wishlist/wishlist_item.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_colors.dart';

/// Tombol hati untuk toggle favorit — dipakai di halaman Wishlist maupun
/// (nanti) di kartu produk halaman Home/Detail begitu Fase 2 Flutter selesai.
/// Cukup drop widget ini di kartu produk mana pun dengan data produknya.
class WishlistToggleButton extends ConsumerWidget {
  final String productId;
  final String name;
  final int price;
  final double rating;
  final String variant;
  final double size;

  const WishlistToggleButton({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.rating,
    this.variant = '',
    this.size = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(wishlistProvider.select((state) => state.isFavorite(productId)));

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? AppColors.error : AppColors.textSecondary,
        size: size,
      ),
      onPressed: () {
        final item = WishlistItem(
          id: 'wishlist-$productId',
          productId: productId,
          name: name,
          variant: variant,
          price: price,
          rating: rating,
        );
        ref.read(wishlistProvider.notifier).toggleFavorite(item);
      },
    );
  }
}
