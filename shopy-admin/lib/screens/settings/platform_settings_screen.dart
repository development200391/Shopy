import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/settings/platform_settings.dart';
import '../../providers/admin_settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class PlatformSettingsScreen extends ConsumerWidget {
  const PlatformSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(adminSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pengaturan Platform')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gagal memuat pengaturan', style: TextStyle(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => ref.invalidate(adminSettingsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (settings) => _SettingsForm(initial: settings),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  final PlatformSettings initial;

  const _SettingsForm({required this.initial});

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _commissionController;
  late final TextEditingController _adminFeeController;
  late final TextEditingController _minWithdrawalController;
  late final TextEditingController _maxWithdrawalsController;
  late final TextEditingController _autoCancelController;
  late final TextEditingController _autoCompleteController;
  late final TextEditingController _lowStockController;
  late DateTime _updatedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _commissionController = TextEditingController(text: _trimZeros(s.commissionPercent));
    _adminFeeController = TextEditingController(text: s.withdrawalAdminFee.toString());
    _minWithdrawalController = TextEditingController(text: s.minWithdrawal.toString());
    _maxWithdrawalsController = TextEditingController(text: s.maxWithdrawalsPerDay.toString());
    _autoCancelController = TextEditingController(text: s.autoCancelHours.toString());
    _autoCompleteController = TextEditingController(text: s.autoCompleteDays.toString());
    _lowStockController = TextEditingController(text: s.lowStockThreshold.toString());
    _updatedAt = s.updatedAt;
  }

  @override
  void dispose() {
    _commissionController.dispose();
    _adminFeeController.dispose();
    _minWithdrawalController.dispose();
    _maxWithdrawalsController.dispose();
    _autoCancelController.dispose();
    _autoCompleteController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  String _trimZeros(double value) {
    final str = value.toStringAsFixed(2);
    return str.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  String? _validatePositiveNumber(String? value, {bool allowZero = true}) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Harus berupa angka';
    if (allowZero ? parsed < 0 : parsed < 1) return allowZero ? 'Tidak boleh negatif' : 'Minimal 1';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(adminSettingsApiServiceProvider)
          .updateSettings(
            commissionPercent: double.parse(_commissionController.text.trim()),
            withdrawalAdminFee: int.parse(_adminFeeController.text.trim()),
            minWithdrawal: int.parse(_minWithdrawalController.text.trim()),
            maxWithdrawalsPerDay: int.parse(_maxWithdrawalsController.text.trim()),
            autoCancelHours: int.parse(_autoCancelController.text.trim()),
            autoCompleteDays: int.parse(_autoCompleteController.text.trim()),
            lowStockThreshold: int.parse(_lowStockController.text.trim()),
          );
      if (!mounted) return;
      setState(() => _updatedAt = updated.updatedAt);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan berhasil disimpan.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Terakhir diubah: ${_formatDateTime(_updatedAt)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingField(
            label: 'Persentase Komisi',
            suffix: '%',
            controller: _commissionController,
            allowDecimal: true,
            validator: (v) => _validatePositiveNumber(v),
          ),
          _SettingField(
            label: 'Biaya Admin Pencairan',
            suffix: 'Rp',
            controller: _adminFeeController,
            validator: (v) => _validatePositiveNumber(v),
          ),
          _SettingField(
            label: 'Minimal Pencairan',
            suffix: 'Rp',
            controller: _minWithdrawalController,
            validator: (v) => _validatePositiveNumber(v),
          ),
          _SettingField(
            label: 'Maks. Pencairan per Hari',
            suffix: 'kali',
            controller: _maxWithdrawalsController,
            validator: (v) => _validatePositiveNumber(v, allowZero: false),
          ),
          _SettingField(
            label: 'Batas Waktu Auto-Batal',
            suffix: 'jam',
            controller: _autoCancelController,
            validator: (v) => _validatePositiveNumber(v, allowZero: false),
          ),
          _SettingField(
            label: 'Batas Waktu Auto-Selesai',
            suffix: 'hari',
            controller: _autoCompleteController,
            validator: (v) => _validatePositiveNumber(v, allowZero: false),
          ),
          _SettingField(
            label: 'Ambang Stok Menipis',
            suffix: 'unit',
            controller: _lowStockController,
            validator: (v) => _validatePositiveNumber(v),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _SettingField extends StatelessWidget {
  final String label;
  final String suffix;
  final TextEditingController controller;
  final bool allowDecimal;
  final String? Function(String?) validator;

  const _SettingField({
    required this.label,
    required this.suffix,
    required this.controller,
    this.allowDecimal = false,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
            inputFormatters: [
              if (allowDecimal)
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              else
                FilteringTextInputFormatter.digitsOnly,
            ],
            validator: validator,
            decoration: InputDecoration(
              suffixText: suffix,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
