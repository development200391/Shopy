import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product/seller_product_summary.dart';
import '../../providers/seller_product_provider.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/auth/auth_text_field.dart';

/// Bottom sheet set/ubah/hapus diskon 1 produk (harga diskon + periode).
void showProductDiscountSheet(BuildContext context, SellerProductSummary product) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (_) => _ProductDiscountSheet(product: product),
  );
}

class _ProductDiscountSheet extends ConsumerStatefulWidget {
  final SellerProductSummary product;

  const _ProductDiscountSheet({required this.product});

  @override
  ConsumerState<_ProductDiscountSheet> createState() => _ProductDiscountSheetState();
}

class _ProductDiscountSheetState extends ConsumerState<_ProductDiscountSheet> {
  late final _priceController = TextEditingController(text: widget.product.discountPrice?.toString() ?? '');
  late DateTime _startAt = widget.product.discountStartAt?.toLocal() ?? DateTime.now();
  late DateTime _endAt = widget.product.discountEndAt?.toLocal() ?? DateTime.now().add(const Duration(days: 7));
  bool _submitting = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startAt : _endAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startAt = picked;
      } else {
        _endAt = picked;
      }
    });
  }

  Future<void> _save() async {
    final discountPrice = int.tryParse(_priceController.text);
    if (discountPrice == null || discountPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harga diskon tidak valid.')));
      return;
    }
    if (discountPrice >= widget.product.price) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Harga diskon harus lebih murah dari harga normal.')));
      return;
    }
    if (!_endAt.isAfter(_startAt)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tanggal berakhir harus setelah tanggal mulai.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(sellerProductApiServiceProvider)
          .setDiscount(widget.product.id, discountPrice: discountPrice, discountStartAt: _startAt, discountEndAt: _endAt);
      _refreshAndClose();
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _clear() async {
    setState(() => _submitting = true);
    try {
      await ref.read(sellerProductApiServiceProvider).clearDiscount(widget.product.id);
      _refreshAndClose();
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _refreshAndClose() {
    ref.invalidate(sellerProductsProvider);
    if (mounted) Navigator.of(context).pop();
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '$day ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atur Diskon', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(widget.product.name, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Harga Diskon (Rp)',
              hint: '${widget.product.price}',
              icon: Icons.local_offer_outlined,
              controller: _priceController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _DateField(label: 'Mulai', date: _formatDate(_startAt), onTap: () => _pickDate(isStart: true)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _DateField(label: 'Berakhir', date: _formatDate(_endAt), onTap: () => _pickDate(isStart: false)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (widget.product.isDiscounted)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : _clear,
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                      child: const Text('Hapus Diskon'),
                    ),
                  ),
                if (widget.product.isDiscounted) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _save,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                          )
                        : const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(date),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
