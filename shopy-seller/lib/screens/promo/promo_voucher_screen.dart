import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product/seller_product_summary.dart';
import '../../models/promo/voucher.dart';
import '../../providers/seller_product_provider.dart';
import '../../providers/seller_voucher_provider.dart';
import '../../services/api_client.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import 'product_discount_sheet.dart';
import 'voucher_form_screen.dart';

enum _PromoTab { voucher, discount, flashSale }

/// Halaman **Promo & Voucher** — desain terpilih: **Bold & Colorful**
/// (lihat `design/assets/promo-voucher-seller-bold-colorful.png`).
class PromoVoucherScreen extends ConsumerStatefulWidget {
  const PromoVoucherScreen({super.key});

  @override
  ConsumerState<PromoVoucherScreen> createState() => _PromoVoucherScreenState();
}

class _PromoVoucherScreenState extends ConsumerState<PromoVoucherScreen> {
  _PromoTab _tab = _PromoTab.voucher;

  Future<void> _createVoucher() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const VoucherFormScreen()));
    if (created == true) ref.invalidate(sellerVouchersProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo & Voucher'),
        actions: [
          if (_tab == _PromoTab.voucher)
            IconButton(icon: const Icon(Icons.add), onPressed: _createVoucher),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                _TabChip(
                  label: 'Voucher Toko',
                  selected: _tab == _PromoTab.voucher,
                  onTap: () => setState(() => _tab = _PromoTab.voucher),
                ),
                const SizedBox(width: AppSpacing.xs),
                _TabChip(
                  label: 'Diskon Produk',
                  selected: _tab == _PromoTab.discount,
                  onTap: () => setState(() => _tab = _PromoTab.discount),
                ),
                const SizedBox(width: AppSpacing.xs),
                _TabChip(
                  label: 'Flash Sale',
                  selected: _tab == _PromoTab.flashSale,
                  onTap: () => setState(() => _tab = _PromoTab.flashSale),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              _PromoTab.voucher => const _VoucherTab(),
              _PromoTab.discount => const _DiscountTab(),
              _PromoTab.flashSale => const _FlashSaleTab(),
            },
          ),
        ],
      ),
      bottomNavigationBar: _tab == _PromoTab.voucher
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ElevatedButton.icon(
                  onPressed: _createVoucher,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Voucher Baru'),
                ),
              ),
            )
          : null,
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
      labelStyle: TextStyle(
        color: selected ? AppColors.onPrimary : AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide.none,
    );
  }
}

class _VoucherTab extends ConsumerWidget {
  const _VoucherTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouchersAsync = ref.watch(sellerVouchersProvider);

    return vouchersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(onRetry: () => ref.invalidate(sellerVouchersProvider)),
      data: (vouchers) {
        if (vouchers.isEmpty) {
          return const Center(
            child: Text('Belum ada voucher. Buat voucher pertama tokomu!', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
          itemCount: vouchers.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _VoucherCard(voucher: vouchers[index]),
        );
      },
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
          const Text('Gagal memuat data', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _VoucherCard extends ConsumerStatefulWidget {
  final Voucher voucher;

  const _VoucherCard({required this.voucher});

  @override
  ConsumerState<_VoucherCard> createState() => _VoucherCardState();
}

class _VoucherCardState extends ConsumerState<_VoucherCard> {
  bool _busy = false;

  Future<void> _toggleActive(bool value) async {
    setState(() => _busy = true);
    try {
      await ref.read(sellerVoucherApiServiceProvider).setActive(widget.voucher.id, value);
      ref.invalidate(sellerVouchersProvider);
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showStats() {
    final v = widget.voucher;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Statistik ${v.code}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatLine('Dipakai', '${v.usedCount}${v.quota != null ? ' / ${v.quota}' : ''} kali'),
            _StatLine('Total diskon diberikan', formatRupiah(v.totalDiscountGiven)),
            _StatLine('Total nilai pesanan', formatRupiah(v.totalOrderValue)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => VoucherFormScreen(voucher: widget.voucher)));
    if (updated == true) ref.invalidate(sellerVouchersProvider);
  }

  String _typeDescription(Voucher v) {
    return switch (v.type) {
      'Percentage' => 'Diskon ${v.value}%',
      'FixedAmount' => 'Diskon ${formatRupiah(v.value)}',
      'FreeShipping' => 'Gratis Ongkir ${formatRupiah(v.value)}',
      _ => v.type,
    };
  }

  String _constraintLine(Voucher v) {
    final parts = <String>[];
    if (v.maxDiscount != null) parts.add('Maks. ${formatRupiah(v.maxDiscount!)}');
    if (v.minPurchase != null) parts.add('Min. belanja ${formatRupiah(v.minPurchase!)}');
    return parts.isEmpty ? 'Tanpa minimum' : parts.join(' · ');
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '$day ${months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.voucher;
    final (statusLabel, statusColor) = switch (v.status) {
      'Active' => ('Aktif', AppColors.success),
      'Scheduled' => ('Terjadwal', Colors.blue),
      'Ended' => ('Berakhir', AppColors.textSecondary),
      _ => ('Nonaktif', AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(v.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                child: Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(_typeDescription(v), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(_constraintLine(v), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${_formatDate(v.startAt)} - ${_formatDate(v.endAt)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (v.quota != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (v.usedCount / v.quota!).clamp(0, 1),
                minHeight: 6,
                backgroundColor: AppColors.divider,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text('${v.usedCount} / ${v.quota} dipakai', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ] else
            Text('${v.usedCount}x dipakai', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              InkWell(
                onTap: _edit,
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
                onTap: _showStats,
                child: const Row(
                  children: [
                    Icon(Icons.bar_chart_outlined, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 2),
                    Text('Statistik', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Spacer(),
              Switch(value: v.isActive, activeThumbColor: AppColors.primary, onChanged: _busy ? null : _toggleActive),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;

  const _StatLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DiscountTab extends ConsumerWidget {
  const _DiscountTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(sellerProductsProvider((status: 'all', search: null)));

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(onRetry: () => ref.invalidate(sellerProductsProvider)),
      data: (products) {
        if (products.isEmpty) {
          return const Center(child: Text('Belum ada produk.', style: TextStyle(color: AppColors.textSecondary)));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _DiscountProductCard(product: products[index]),
        );
      },
    );
  }
}

class _DiscountProductCard extends StatelessWidget {
  final SellerProductSummary product;

  const _DiscountProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showProductDiscountSheet(context, product),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
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
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  if (product.isDiscounted) ...[
                    Row(
                      children: [
                        Text(
                          formatRupiah(product.price),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatRupiah(product.discountPrice!),
                          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ] else
                    Text(formatRupiah(product.price), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Text(
              product.isDiscounted ? 'Ubah Diskon' : 'Atur Diskon',
              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashSaleTab extends StatelessWidget {
  const _FlashSaleTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_outlined, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            const Text('Flash Sale belum tersedia', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Fitur ini akan hadir di pembaruan berikutnya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
