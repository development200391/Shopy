import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product/seller_product_summary.dart';
import '../../providers/seller_product_provider.dart';
import '../../services/api_client.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

const _lowStockThreshold = 10;

/// Halaman **Atur Stok & Harga** — edit cepat massal tanpa buka detail produk.
/// Desain terpilih: **Bold & Colorful** (lihat `design/assets/stok-harga-seller-bold-colorful.png`).
class StockPriceScreen extends ConsumerStatefulWidget {
  const StockPriceScreen({super.key});

  @override
  ConsumerState<StockPriceScreen> createState() => _StockPriceScreenState();
}

class _StockPriceScreenState extends ConsumerState<StockPriceScreen> {
  final _searchController = TextEditingController();
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _stockControllers = {};
  final Set<String> _dirtyIds = {};
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    for (final c in _stockControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _priceControllerFor(SellerProductSummary p) {
    return _priceControllers.putIfAbsent(p.id, () => TextEditingController(text: '${p.price}'));
  }

  TextEditingController _stockControllerFor(SellerProductSummary p) {
    return _stockControllers.putIfAbsent(p.id, () => TextEditingController(text: '${p.stock}'));
  }

  void _markDirty(String id) {
    if (_dirtyIds.add(id)) setState(() {});
  }

  Future<void> _save() async {
    if (_dirtyIds.isEmpty) return;

    setState(() => _saving = true);
    try {
      final items = _dirtyIds
          .map(
            (id) => {
              'id': id,
              'price': int.tryParse(_priceControllers[id]?.text ?? '') ?? 0,
              'stock': int.tryParse(_stockControllers[id]?.text ?? '') ?? 0,
            },
          )
          .toList();

      await ref.read(sellerProductApiServiceProvider).bulkUpdate(items);
      _dirtyIds.clear();
      ref.invalidate(sellerProductsProvider((status: 'all', search: null)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perubahan disimpan.')));
      setState(() {});
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(sellerProductsProvider((status: 'all', search: null)));

    return Scaffold(
      appBar: AppBar(title: const Text('Atur Stok & Harga')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Gagal memuat produk')),
        data: (allProducts) {
          final lowStockCount = allProducts
              .where((p) => p.isActive && p.stock <= _lowStockThreshold)
              .length;
          final query = _searchController.text.trim().toLowerCase();
          final products = query.isEmpty
              ? allProducts
              : allProducts.where((p) => p.name.toLowerCase().contains(query)).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lowStockCount > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.warning),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$lowStockCount produk stoknya menipis',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Segera tambah stok biar tetap bisa dibeli',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari produk...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppColors.primary.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _StockPriceCard(
                      product: product,
                      priceController: _priceControllerFor(product),
                      stockController: _stockControllerFor(product),
                      lowStock: product.isActive && product.stock <= _lowStockThreshold,
                      onDirty: () => _markDirty(product.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_dirtyIds.isEmpty || _saving) ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                    )
                  : Text('Simpan Perubahan (${_dirtyIds.length})'),
            ),
          ),
        ),
      ),
    );
  }
}

class _StockPriceCard extends StatelessWidget {
  final SellerProductSummary product;
  final TextEditingController priceController;
  final TextEditingController stockController;
  final bool lowStock;
  final VoidCallback onDirty;

  const _StockPriceCard({
    required this.product,
    required this.priceController,
    required this.stockController,
    required this.lowStock,
    required this.onDirty,
  });

  @override
  Widget build(BuildContext context) {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: product.imageUrl == null
                  ? Container(color: AppColors.primary.withValues(alpha: 0.08))
                  : Image.network('${resolveApiBaseUrl()}${product.imageUrl}', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (lowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Stok rendah',
                          style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _InlineField(
                        label: 'Harga',
                        prefix: 'Rp',
                        controller: priceController,
                        onChanged: (_) => onDirty(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _InlineField(label: 'Stok', controller: stockController, onChanged: (_) => onDirty()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  final String label;
  final String? prefix;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _InlineField({
    required this.label,
    this.prefix,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            isDense: true,
            prefixText: prefix != null ? '$prefix ' : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
