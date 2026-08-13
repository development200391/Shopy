import 'package:flutter/material.dart';

import '../../models/catalog/product_summary.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../shared/placeholder_thumbnail.dart';
import '../wishlist/wishlist_toggle_button.dart';

/// Kartu produk 2-kolom untuk grid Home & Search — desain "Bold & Colorful".
class ProductCard extends StatelessWidget {
  final ProductSummary product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  const Positioned.fill(child: PlaceholderThumbnail()),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: WishlistToggleButton(
                          productId: product.id,
                          name: product.name,
                          price: product.price,
                          rating: product.ratingAverage,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            if (product.isDiscounted)
              Text(
                formatRupiah(product.originalPrice!),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            Text(
              formatRupiah(product.price),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  product.ratingAverage.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
