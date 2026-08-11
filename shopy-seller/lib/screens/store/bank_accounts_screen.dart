import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/store/bank_account.dart';
import '../../providers/store_settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class BankAccountsScreen extends ConsumerWidget {
  const BankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bankAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rekening Bank')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(child: Text(state.error!))
          : state.items.isEmpty
          ? const Center(child: Text('Belum ada rekening. Tambah rekening buat pencairan dana.'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _BankAccountCard(account: state.items[index]),
            ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => const _BankAccountFormSheet(),
    );
  }
}

class _BankAccountCard extends ConsumerWidget {
  final BankAccount account;

  const _BankAccountCard({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(account.bankName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (account.isDefault) ...[
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
                  ],
                ),
                Text('${account.accountNumber} · ${account.accountHolderName}'),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'default') {
                ref.read(bankAccountsProvider.notifier).setDefault(account.id);
              } else if (value == 'delete') {
                ref.read(bankAccountsProvider.notifier).delete(account.id);
              }
            },
            itemBuilder: (context) => [
              if (!account.isDefault) const PopupMenuItem(value: 'default', child: Text('Jadikan utama')),
              const PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        ],
      ),
    );
  }
}

class _BankAccountFormSheet extends ConsumerStatefulWidget {
  const _BankAccountFormSheet();

  @override
  ConsumerState<_BankAccountFormSheet> createState() => _BankAccountFormSheetState();
}

class _BankAccountFormSheetState extends ConsumerState<_BankAccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bankCode = TextEditingController();
  final _bankName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _accountHolderName = TextEditingController();
  bool _isDefault = false;
  bool _submitting = false;

  @override
  void dispose() {
    _bankCode.dispose();
    _bankName.dispose();
    _accountNumber.dispose();
    _accountHolderName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(bankAccountsProvider.notifier)
          .create(
            bankCode: _bankCode.text.trim().toUpperCase(),
            bankName: _bankName.text.trim(),
            accountNumber: _accountNumber.text.trim(),
            accountHolderName: _accountHolderName.text.trim(),
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
              Text('Tambah Rekening Bank', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _field(_bankCode, 'Kode Bank (mis. BCA, BNI)'),
              _field(_bankName, 'Nama Bank (mis. Bank Central Asia)'),
              _field(_accountNumber, 'Nomor Rekening', keyboardType: TextInputType.number),
              _field(_accountHolderName, 'Nama Pemilik Rekening'),
              CheckboxListTile(
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value ?? false),
                title: const Text('Jadikan rekening utama'),
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
                      : const Text('Simpan Rekening'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) => (value == null || value.trim().isEmpty) ? '$label wajib diisi' : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
