import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/catalog/product_summary.dart';
import '../../models/store/store_public_profile.dart';
import '../../providers/store_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/products/product_card.dart';
import '../products/product_detail_screen.dart';

/// Halaman publik Profil Toko — dibuka dari tombol "Kunjungi Toko" di Detail
/// Produk. Desain mengikuti token yang sama seperti halaman lain (Bold & Colorful).
class StoreProfileScreen extends ConsumerWidget {
  final String slug;

  const StoreProfileScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(storeProfileProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: storeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _ErrorState(onRetry: () => ref.invalidate(storeProfileProvider(slug))),
        data: (store) => _StoreProfileBody(store: store),
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
          const Text('Gagal memuat toko', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Kembali')),
        ],
      ),
    );
  }
}

class _StoreProfileBody extends ConsumerWidget {
  final StorePublicProfile store;

  const _StoreProfileBody({required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(storeProductsProvider(store.slug));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 180,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: store.bannerUrl == null
                ? const ColoredBox(color: AppColors.primary)
                : Image.network(
                    '${resolveApiBaseUrl()}${store.bannerUrl}',
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: store.logoUrl == null
                          ? null
                          : NetworkImage('${resolveApiBaseUrl()}${store.logoUrl}'),
                      child: store.logoUrl == null
                          ? const Icon(Icons.storefront_outlined, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${store.ratingAverage.toStringAsFixed(1)} (${store.ratingCount})',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '${store.productCount} produk · ${store.followerCount} pengikut',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (store.description != null && store.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(store.description!, style: const TextStyle(color: AppColors.textSecondary)),
                ],
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                const Text('Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
        productsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: Text('Gagal memuat produk toko ini')),
            ),
          ),
          data: (products) => products.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: Text('Toko ini belum punya produk.')),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 0.62,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _StoreProductCard(product: products[index]),
                      childCount: products.length,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _StoreProductCard extends StatelessWidget {
  final ProductSummary product;

  const _StoreProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return ProductCard(
      product: product,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: product.slug))),
    );
  }
}
