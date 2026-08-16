import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/moderation/admin_product.dart';
import '../../providers/admin_product_provider.dart';
import '../../providers/admin_product_list_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';

class ProductSearchScreen extends ConsumerStatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  ConsumerState<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends ConsumerState<ProductSearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmTakedown(BuildContext context, WidgetRef ref, AdminProductListItem product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Takedown Produk'),
        content: Text('Produk "${product.name}" akan disembunyikan dari toko ${product.storeName}. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Takedown'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(adminModerationApiServiceProvider).takedownProduct(product.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk berhasil di-takedown.')));
      ref.read(adminProductListProvider.notifier).reload();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(adminProductListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // `centerTitle: false` wajib eksplisit — tema app memusatkan judul, dan
        // kolom pencarian yang ikut terpusat tampak seperti judul kepotong,
        // bukan seperti input yang bisa diketik.
        centerTitle: false,
        title: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Cari produk atau toko...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            prefixIconConstraints: BoxConstraints(minWidth: 32),
          ),
          onSubmitted: (value) => ref.read(adminProductListProvider.notifier).setSearch(value.trim()),
        ),
      ),
      body: _ProductListBody(list: list, onTakedown: (product) => _confirmTakedown(context, ref, product)),
    );
  }
}

class _ProductListBody extends ConsumerWidget {
  final AdminProductListState list;
  final void Function(AdminProductListItem) onTakedown;

  const _ProductListBody({required this.list, required this.onTakedown});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (list.loading && list.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.error != null && list.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat daftar produk', style: TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => ref.read(adminProductListProvider.notifier).reload(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (list.items.isEmpty) {
      return const Center(
        child: Text('Tidak ada produk ditemukan.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminProductListProvider.notifier).reload(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: list.items.length + (list.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= list.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: list.loading
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: () => ref.read(adminProductListProvider.notifier).loadMore(),
                        child: const Text('Muat Lebih Banyak'),
                      ),
              ),
            );
          }

          final product = list.items[index];
          return _ProductCard(product: product, onTakedown: () => onTakedown(product));
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final AdminProductListItem product;
  final VoidCallback onTakedown;

  const _ProductCard({required this.product, required this.onTakedown});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: product.imageUrl != null
                ? Image.network(
                    product.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _placeholderThumb(),
                  )
                : _placeholderThumb(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(product.storeName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(formatRupiah(product.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Stok ${product.stock}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    if (!product.isActive) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const Text('Nonaktif', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Takedown',
            onPressed: onTakedown,
          ),
        ],
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
    );
  }
}
