import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/address_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Bottom sheet form tambah alamat baru, dibuka dari "+ Tambah Alamat Baru"
/// di [showAddressPickerSheet] atau saat user belum punya alamat sama sekali.
Future<bool?> showAddressFormSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (sheetContext) => const _AddressFormSheet(),
  );
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  const _AddressFormSheet();

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController(text: 'Rumah');
  final _recipientName = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _fullAddress = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _postalCode = TextEditingController();
  bool _isDefault = false;
  bool _submitting = false;

  @override
  void dispose() {
    _label.dispose();
    _recipientName.dispose();
    _phoneNumber.dispose();
    _fullAddress.dispose();
    _city.dispose();
    _province.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(addressProvider.notifier)
          .create(
            label: _label.text.trim(),
            recipientName: _recipientName.text.trim(),
            phoneNumber: _phoneNumber.text.trim(),
            fullAddress: _fullAddress.text.trim(),
            city: _city.text.trim(),
            province: _province.text.trim(),
            postalCode: _postalCode.text.trim(),
            isDefault: _isDefault,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              Text('Tambah Alamat Baru', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _field(_label, 'Label (mis. Rumah, Kantor)'),
              _field(_recipientName, 'Nama Penerima'),
              _field(_phoneNumber, 'Nomor HP', keyboardType: TextInputType.phone),
              _field(_fullAddress, 'Alamat Lengkap', maxLines: 3),
              _field(_city, 'Kota'),
              _field(_province, 'Provinsi'),
              _field(_postalCode, 'Kode Pos', keyboardType: TextInputType.number),
              CheckboxListTile(
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value ?? false),
                title: const Text('Jadikan alamat utama'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Alamat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) => (value == null || value.trim().isEmpty) ? '$label wajib diisi' : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
