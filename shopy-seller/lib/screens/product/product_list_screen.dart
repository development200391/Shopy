import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product/seller_product_summary.dart';
import '../../providers/seller_product_provider.dart';
import '../../services/api_client.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import 'product_form_screen.dart';

enum _ProductTab { all, active, inactive, outOfStock }

/// Halaman **Daftar Produk** — desain terpilih: **Bold & Colorful**
/// (lihat `design/assets/produk-list-seller-bold-colorful.png`).
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  _ProductTab _tab = _ProductTab.all;
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ({String status, String? search}) get _filter =>
      (status: 'all', search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim());

  bool _matchesTab(SellerProductSummary p, _ProductTab tab) {
    return switch (tab) {
      _ProductTab.all => true,
      _ProductTab.active => p.isActive && p.stock > 0,
      _ProductTab.inactive => !p.isActive,
      _ProductTab.outOfStock => p.isActive && p.stock == 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(sellerProductsProvider(_filter));

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Cari produk...', border: InputBorder.none),
                onChanged: (_) => ref.invalidate(sellerProductsProvider(_filter)),
              )
            : const Text('Produk Saya'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _searchController.clear();
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(
            context,
          ).push<bool>(MaterialPageRoute(builder: (_) => const ProductFormScreen()));
          if (created == true) ref.invalidate(sellerProductsProvider(_filter));
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _ErrorState(onRetry: () => ref.invalidate(sellerProductsProvider(_filter))),
        data: (products) {
          final filtered = products.where((p) => _matchesTab(p, _tab)).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    _TabChip(
                      label: 'Semua ${products.length}',
                      selected: _tab == _ProductTab.all,
                      onTap: () => setState(() => _tab = _ProductTab.all),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _TabChip(
                      label: 'Aktif ${products.where((p) => _matchesTab(p, _ProductTab.active)).length}',
                      selected: _tab == _ProductTab.active,
                      onTap: () => setState(() => _tab = _ProductTab.active),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _TabChip(
                      label:
                          'Nonaktif ${products.where((p) => _matchesTab(p, _ProductTab.inactive)).length}',
                      selected: _tab == _ProductTab.inactive,
                      onTap: () => setState(() => _tab = _ProductTab.inactive),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _TabChip(
                      label:
                          'Habis ${products.where((p) => _matchesTab(p, _ProductTab.outOfStock)).length}',
                      selected: _tab == _ProductTab.outOfStock,
                      onTap: () => setState(() => _tab = _ProductTab.outOfStock),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Belum ada produk di kategori ini.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) => _ProductCard(
                          product: filtered[index],
                          onChanged: () => ref.invalidate(sellerProductsProvider(_filter)),
                        ),
                      ),
              ),
            ],
          );
        },
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
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? AppColors.onPrimary : AppColors.textPrimary),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide.none,
    );
  }
}

class _ProductCard extends ConsumerStatefulWidget {
  final SellerProductSummary product;
  final VoidCallback onChanged;

  const _ProductCard({required this.product, required this.onChanged});

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  bool _busy = false;

  Future<void> _toggleActive(bool value) async {
    setState(() => _busy = true);
    try {
      await ref.read(sellerProductApiServiceProvider).setActive(widget.product.id, value);
      widget.onChanged();
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text('"${widget.product.name}" akan dihapus dari toko kamu.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(sellerProductApiServiceProvider).deleteProduct(widget.product.id);
      widget.onChanged();
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final lowStock = product.isActive && product.stock > 0 && product.stock <= 10;
    final outOfStock = product.stock == 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: product.imageUrl == null
                      ? Container(color: AppColors.primary.withValues(alpha: 0.08))
                      : Image.network(
                          '${resolveApiBaseUrl()}${product.imageUrl}',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              if (lowStock || outOfStock)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: outOfStock ? AppColors.error : AppColors.warning,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      outOfStock ? 'Stok Habis' : 'Stok Menipis',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(product.price),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stok ${product.stock} · Terjual ${product.soldCount}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        final updated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => ProductFormScreen(productId: product.id)),
                        );
                        if (updated == true) widget.onChanged();
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                          SizedBox(width: 2),
                          Text('Ubah', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    InkWell(
                      onTap: _delete,
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                          SizedBox(width: 2),
                          Text('Hapus', style: TextStyle(color: AppColors.error, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: product.isActive,
                activeThumbColor: AppColors.primary,
                onChanged: _busy ? null : _toggleActive,
              ),
              Text(
                product.isActive ? 'Aktif' : 'Nonaktif',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
