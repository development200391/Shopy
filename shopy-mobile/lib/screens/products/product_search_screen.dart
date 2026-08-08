import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/catalog/product_sort.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/catalog_search_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/products/product_card.dart';
import '../../widgets/shared/app_bottom_nav.dart';
import '../cart/cart_screen.dart';
import '../home/home_screen.dart';
import '../orders/order_history_screen.dart';
import '../wishlist/wishlist_screen.dart';
import 'product_detail_screen.dart';

/// Halaman Pencarian & Filter Produk. Desain terpilih: **Bold & Colorful**
/// (lihat `design/assets/search-filter-bold-colorful.png`).
///
/// Bisa dibuka dari search bar Home (tanpa filter) atau dari tap kategori di
/// Home ([categoryId]/[categoryName] terisi).
class ProductSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? categoryId;
  final String? categoryName;

  const ProductSearchScreen({super.key, this.initialQuery, this.categoryId, this.categoryName});

  @override
  ConsumerState<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends ConsumerState<ProductSearchScreen> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialQuery ?? '');

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(productSearchProvider.notifier)
          .init(query: widget.initialQuery, categoryId: widget.categoryId, categoryName: widget.categoryName),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              textInputAction: TextInputAction.search,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Cari produk...',
                                isDense: true,
                              ),
                              onSubmitted: (value) => ref.read(productSearchProvider.notifier).search(value),
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            InkWell(
                              onTap: () {
                                _controller.clear();
                                ref.read(productSearchProvider.notifier).search('');
                              },
                              child: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  state.query.isEmpty
                      ? '${state.totalCount} produk'
                      : '${state.totalCount} hasil untuk "${state.query}"',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  _SortButton(sort: state.sort),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterButton(minPrice: state.minPrice, maxPrice: state.maxPrice),
                ],
              ),
            ),
            if (state.categoryId != null || state.hasPriceFilter) ...[
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    if (state.categoryId != null)
                      _FilterChip(
                        label: state.categoryName ?? 'Kategori',
                        onDeleted: () => ref.read(productSearchProvider.notifier).clearCategory(),
                      ),
                    if (state.hasPriceFilter)
                      _FilterChip(
                        label: _priceRangeLabel(state.minPrice, state.maxPrice),
                        onDeleted: () => ref
                            .read(productSearchProvider.notifier)
                            .setPriceRange(minPrice: null, maxPrice: null),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            Expanded(child: _ResultsList(state: state)),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentTab: AppTab.home, onTap: (tab) => _onTabTap(context, tab)),
    );
  }

  void _onTabTap(BuildContext context, AppTab tab) {
    switch (tab) {
      case AppTab.home:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
        return;
      case AppTab.keranjang:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CartScreen()));
        return;
      case AppTab.wishlist:
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const WishlistScreen()));
        return;
      case AppTab.profil:
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
        return;
      case AppTab.kategori:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Halaman ini belum tersedia.')));
        return;
    }
  }

  String _priceRangeLabel(int? min, int? max) {
    if (min != null && max != null) return '${formatRupiah(min)} - ${formatRupiah(max)}';
    if (min != null) return 'Min ${formatRupiah(min)}';
    return 'Maks ${formatRupiah(max!)}';
  }
}

class _ResultsList extends ConsumerWidget {
  final ProductSearchState state;

  const _ResultsList({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat produk', style: TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => ref.read(productSearchProvider.notifier).search(state.query),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return const Center(
        child: Text('Tidak ada produk ditemukan', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final product = state.items[index];
            return ProductCard(
              product: product,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: product.slug))),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.hasMore)
          Center(
            child: state.loading
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    onPressed: () => ref.read(productSearchProvider.notifier).loadMore(),
                    child: const Text('Muat Lebih Banyak'),
                  ),
          ),
      ],
    );
  }
}

class _SortButton extends ConsumerWidget {
  final ProductSort sort;

  const _SortButton({required this.sort});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<ProductSort>(
      initialValue: sort,
      onSelected: (value) => ref.read(productSearchProvider.notifier).setSort(value),
      itemBuilder: (context) => [
        for (final option in ProductSort.values)
          PopupMenuItem(value: option, child: Text(option.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Urutkan: ${sort.label}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends ConsumerWidget {
  final int? minPrice;
  final int? maxPrice;

  const _FilterButton({required this.minPrice, required this.maxPrice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showFilterSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 16),
            SizedBox(width: 4),
            Text('Filter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilterSheet(BuildContext context, WidgetRef ref) {
    final minController = TextEditingController(text: minPrice?.toString() ?? '');
    final maxController = TextEditingController(text: maxPrice?.toString() ?? '');

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: AppSpacing.md + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rentang Harga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga Minimum', prefixText: 'Rp '),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga Maksimum', prefixText: 'Rp '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () {
                  ref
                      .read(productSearchProvider.notifier)
                      .setPriceRange(
                        minPrice: int.tryParse(minController.text.trim()),
                        maxPrice: int.tryParse(maxController.text.trim()),
                      );
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Terapkan'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _FilterChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primary),
      onDeleted: onDeleted,
      visualDensity: VisualDensity.compact,
    );
  }
}
