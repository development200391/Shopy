import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/promo/voucher.dart';
import '../../providers/seller_voucher_provider.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/auth/auth_text_field.dart';

const _voucherTypes = [
  (value: 'Percentage', label: 'Persentase (%)'),
  (value: 'FixedAmount', label: 'Potongan Tetap (Rp)'),
  (value: 'FreeShipping', label: 'Gratis Ongkir'),
];

/// Dipakai untuk **Buat** (voucher null) maupun **Ubah** Voucher.
class VoucherFormScreen extends ConsumerStatefulWidget {
  final Voucher? voucher;

  const VoucherFormScreen({super.key, this.voucher});

  bool get isEdit => voucher != null;

  @override
  ConsumerState<VoucherFormScreen> createState() => _VoucherFormScreenState();
}

class _VoucherFormScreenState extends ConsumerState<VoucherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _codeController = TextEditingController(text: widget.voucher?.code ?? '');
  late final _valueController = TextEditingController(text: widget.voucher?.value.toString() ?? '');
  late final _maxDiscountController = TextEditingController(text: widget.voucher?.maxDiscount?.toString() ?? '');
  late final _minPurchaseController = TextEditingController(text: widget.voucher?.minPurchase?.toString() ?? '');
  late final _quotaController = TextEditingController(text: widget.voucher?.quota?.toString() ?? '');
  late String _type = widget.voucher?.type ?? _voucherTypes.first.value;
  late DateTime _startAt = widget.voucher?.startAt.toLocal() ?? DateTime.now();
  late DateTime _endAt = widget.voucher?.endAt.toLocal() ?? DateTime.now().add(const Duration(days: 7));
  bool _submitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _maxDiscountController.dispose();
    _minPurchaseController.dispose();
    _quotaController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endAt.isBefore(_startAt) || _endAt.isAtSameMomentAs(_startAt)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tanggal berakhir harus setelah tanggal mulai.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final data = {
        'code': _codeController.text.trim(),
        'type': _type,
        'value': int.parse(_valueController.text),
        'maxDiscount': _maxDiscountController.text.trim().isEmpty ? null : int.parse(_maxDiscountController.text),
        'minPurchase': _minPurchaseController.text.trim().isEmpty ? null : int.parse(_minPurchaseController.text),
        'quota': _quotaController.text.trim().isEmpty ? null : int.parse(_quotaController.text),
        'startAt': _startAt.toUtc().toIso8601String(),
        'endAt': _endAt.toUtc().toIso8601String(),
      };

      final api = ref.read(sellerVoucherApiServiceProvider);
      if (widget.isEdit) {
        await api.updateVoucher(widget.voucher!.id, data);
      } else {
        await api.createVoucher(data);
      }
      ref.invalidate(sellerVouchersProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '$day ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isFreeShipping = _type == 'FreeShipping';

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Ubah Voucher' : 'Buat Voucher Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthTextField(
                label: 'Kode Voucher',
                hint: 'Contoh: HEMAT20',
                icon: Icons.confirmation_number_outlined,
                controller: _codeController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Kode voucher wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Tipe Voucher', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.local_offer_outlined)),
                items: [
                  for (final type in _voucherTypes) DropdownMenuItem(value: type.value, child: Text(type.label)),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                label: isFreeShipping ? 'Maksimal Ongkir Ditanggung (Rp)' : (_type == 'Percentage' ? 'Nilai Diskon (%)' : 'Nilai Diskon (Rp)'),
                hint: '0',
                icon: Icons.payments_outlined,
                controller: _valueController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nilai wajib diisi';
                  if (int.tryParse(v) == null) return 'Nilai harus angka';
                  return null;
                },
              ),
              if (!isFreeShipping) ...[
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  label: 'Maksimal Diskon (Rp, opsional)',
                  hint: 'Tanpa batas',
                  icon: Icons.trending_down,
                  controller: _maxDiscountController,
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                label: 'Minimal Belanja (Rp, opsional)',
                hint: 'Tanpa minimum',
                icon: Icons.shopping_cart_outlined,
                controller: _minPurchaseController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                label: 'Kuota Pemakaian (opsional)',
                hint: 'Tanpa batas',
                icon: Icons.people_outline,
                controller: _quotaController,
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                        )
                      : Text(widget.isEdit ? 'Simpan Perubahan' : 'Buat Voucher'),
                ),
              ),
            ],
          ),
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
