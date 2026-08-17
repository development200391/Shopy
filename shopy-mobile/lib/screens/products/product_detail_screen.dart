import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/catalog/product_detail.dart';
import '../../models/review/review.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/review_provider.dart';
import '../../services/api_client.dart';
import '../../services/review_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/shared/placeholder_thumbnail.dart';
import '../../widgets/wishlist/wishlist_toggle_button.dart';
import '../stores/store_profile_screen.dart';

/// Halaman Detail Produk. Desain terpilih: **Bold & Colorful** (lihat
/// `design/assets/product-detail-bold-colorful.png`).
///
/// Catatan: mockup juga menampilkan pilihan warna/ukuran & harga coret
/// (diskon), tapi model `Product` di backend belum punya data varian/diskon —
/// jadi bagian itu sengaja tidak ditampilkan alih-alih dipalsukan.
class ProductDetailScreen extends ConsumerWidget {
  final String slug;

  const ProductDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(onRetry: () => ref.invalidate(productDetailProvider(slug))),
        data: (product) => _ProductDetailBody(product: product),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Gagal memuat produk', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailBody extends ConsumerWidget {
  final ProductDetail product;

  const _ProductDetailBody({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroImage(product: product),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryTag(name: product.categoryName),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        product.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${product.ratingAverage.toStringAsFixed(1)} (${product.ratingCount} ulasan)',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (product.isDiscounted)
                        Text(
                          formatRupiah(product.originalPrice!),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        formatRupiah(product.price),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StoreInfoCard(product: product),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      const Text('Deskripsi Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        (product.description == null || product.description!.isEmpty)
                            ? 'Belum ada deskripsi untuk produk ini.'
                            : product.description!,
                        style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      const Text('Ulasan Pembeli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${product.ratingAverage.toStringAsFixed(1)} dari ${product.ratingCount} ulasan',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ReviewSection(productId: product.id),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomBar(product: product),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  final ProductDetail product;

  const _HeroImage({required this.product});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: ProductThumbnail(imageUrl: product.imageUrl, borderRadius: 0),
          ),
          Positioned(
            left: AppSpacing.md,
            top: AppSpacing.md,
            child: _CircleBackButton(onTap: () => Navigator.of(context).pop()),
          ),
          Positioned(
            right: AppSpacing.md,
            top: AppSpacing.md,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: WishlistToggleButton(
                productId: product.id,
                name: product.name,
                price: product.price,
                rating: product.ratingAverage,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String name;

  const _CategoryTag({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(name, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _StoreInfoCard extends StatelessWidget {
  final ProductDetail product;

  const _StoreInfoCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StoreProfileScreen(slug: product.storeSlug)),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                product.storeName,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Text('Kunjungi Toko', style: TextStyle(color: AppColors.primary, fontSize: 12)),
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  final ProductDetail product;

  const _BottomBar({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: WishlistToggleButton(
                  productId: product.id,
                  name: product.name,
                  price: product.price,
                  rating: product.ratingAverage,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: product.stock <= 0
                        ? null
                        : () async {
                            try {
                              await ref.read(cartProvider.notifier).addItem(productId: product.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${product.name} ditambahkan ke keranjang')),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: Text(product.stock <= 0 ? 'Stok Habis' : 'Tambah ke Keranjang'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewSection extends ConsumerStatefulWidget {
  final String productId;

  const _ReviewSection({required this.productId});

  @override
  ConsumerState<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<_ReviewSection> {
  List<Review> _reviews = [];
  int _page = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final result = await ref.read(reviewApiServiceProvider).getProductReviews(widget.productId, page: 1);
      if (!mounted) return;
      setState(() {
        _reviews = result.items;
        _page = result.page;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } on ReviewException {
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(reviewApiServiceProvider).getProductReviews(widget.productId, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _reviews = [..._reviews, ...result.items];
        _page = result.page;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } on ReviewException {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error && _reviews.isEmpty) {
      return const Text('Gagal memuat ulasan.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12));
    }
    if (_reviews.isEmpty) {
      return const Text('Belum ada ulasan untuk produk ini.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final review in _reviews) _ReviewCard(review: review),
        if (_hasMore)
          Center(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(onPressed: _loadMore, child: const Text('Muat Lebih Banyak')),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: review.buyerAvatarUrl == null
                    ? null
                    : NetworkImage('${resolveApiBaseUrl()}${review.buyerAvatarUrl}'),
                child: review.buyerAvatarUrl == null
                    ? const Icon(Icons.person_outline, color: AppColors.primary, size: 16)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(review.buyerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    size: 14,
                    color: i < review.rating ? Colors.amber : AppColors.divider,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(review.comment!, style: const TextStyle(fontSize: 13)),
          ],
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '${resolveApiBaseUrl()}${review.imageUrls[index]}',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          if (review.sellerReply != null && review.sellerReply!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Balasan Penjual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(review.sellerReply!, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
