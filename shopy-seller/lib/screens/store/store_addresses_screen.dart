import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/store/store_address.dart';
import '../../providers/store_settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class StoreAddressesScreen extends ConsumerWidget {
  const StoreAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeAddressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alamat & Pengiriman')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(child: Text(state.error!))
          : state.items.isEmpty
          ? const Center(child: Text('Belum ada alamat. Tambah alamat pickup pertama kamu.'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _AddressCard(address: state.items[index]),
            ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => const _AddressFormSheet(),
    );
  }
}

class _AddressCard extends ConsumerWidget {
  final StoreAddress address;

  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
              Text(address.label, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (address.isDefault) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Utama', style: TextStyle(color: AppColors.primary, fontSize: 11)),
                ),
              ],
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'default') {
                    ref.read(storeAddressesProvider.notifier).setDefault(address.id);
                  } else if (value == 'delete') {
                    ref.read(storeAddressesProvider.notifier).delete(address.id);
                  }
                },
                itemBuilder: (context) => [
                  if (!address.isDefault)
                    const PopupMenuItem(value: 'default', child: Text('Jadikan utama')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${address.picName} · ${address.phoneNumber}'),
          Text(
            '${address.fullAddress}, ${address.city}, ${address.province} ${address.postalCode}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  const _AddressFormSheet();

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController(text: 'Gudang');
  final _picName = TextEditingController();
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
    _picName.dispose();
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
          .read(storeAddressesProvider.notifier)
          .create(
            label: _label.text.trim(),
            picName: _picName.text.trim(),
            phoneNumber: _phoneNumber.text.trim(),
            fullAddress: _fullAddress.text.trim(),
            city: _city.text.trim(),
            province: _province.text.trim(),
            postalCode: _postalCode.text.trim(),
            isDefault: _isDefault,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
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
              Text('Tambah Alamat Pickup', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _field(_label, 'Label (mis. Gudang Utama)'),
              _field(_picName, 'Nama Penanggung Jawab'),
              _field(_phoneNumber, 'Nomor HP', keyboardType: TextInputType.phone),
              _field(_fullAddress, 'Alamat Lengkap', maxLines: 3),
              _field(_city, 'Kota/Kabupaten'),
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
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
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
