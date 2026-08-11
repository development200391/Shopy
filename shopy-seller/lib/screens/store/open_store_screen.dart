import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/seller_provider.dart';
import '../../routing/post_auth_router.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/auth/auth_text_field.dart';

/// Wizard "Buka Toko" 3 langkah (Data Toko → Alamat → Verifikasi), sesuai mockup
/// `daftar-toko-seller-bold-colorful.png` (langkah 1). Data 3 langkah dikumpulkan
/// lokal, baru dikirim sekali di langkah terakhir — lihat TASKSELLER.md Fase 1.
class OpenStoreScreen extends ConsumerStatefulWidget {
  const OpenStoreScreen({super.key});

  @override
  ConsumerState<OpenStoreScreen> createState() => _OpenStoreScreenState();
}

class _OpenStoreScreenState extends ConsumerState<OpenStoreScreen> {
  final _pageController = PageController();
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  int _step = 0;
  bool _isSubmitting = false;

  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _addressLabelController = TextEditingController(text: 'Gudang Utama');
  final _addressPicNameController = TextEditingController();
  final _addressPhoneController = TextEditingController();
  final _addressFullAddressController = TextEditingController();
  final _addressCityController = TextEditingController();
  final _addressProvinceController = TextEditingController();
  final _addressPostalCodeController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _slugController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _addressLabelController.dispose();
    _addressPicNameController.dispose();
    _addressPhoneController.dispose();
    _addressFullAddressController.dispose();
    _addressCityController.dispose();
    _addressProvinceController.dispose();
    _addressPostalCodeController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_step == 0 && !_step1FormKey.currentState!.validate()) return;
    if (_step == 1 && !_step2FormKey.currentState!.validate()) return;
    _goToStep(_step + 1);
  }

  void _uploadNotAvailableYet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unggah logo tersedia setelah verifikasi toko.')),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final response = await ref
          .read(sellerApiServiceProvider)
          .openStore(
            name: _nameController.text.trim(),
            slug: _slugController.text.trim(),
            description: _descriptionController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            addressLabel: _addressLabelController.text.trim(),
            addressPicName: _addressPicNameController.text.trim(),
            addressPhoneNumber: _addressPhoneController.text.trim(),
            addressFullAddress: _addressFullAddressController.text.trim(),
            addressCity: _addressCityController.text.trim(),
            addressProvince: _addressProvinceController.text.trim(),
            addressPostalCode: _addressPostalCodeController.text.trim(),
          );
      await ref.read(authProvider.notifier).refreshSessionFrom(response);
      if (!mounted) return;
      await navigateAfterAuth(context, ref);
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _step == 0 ? () => Navigator.of(context).maybePop() : () => _goToStep(_step - 1),
        ),
        title: const Text('Buka Toko Gratis'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: _StepIndicator(step: _step),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DataTokoStep(
                  formKey: _step1FormKey,
                  nameController: _nameController,
                  slugController: _slugController,
                  phoneController: _phoneController,
                  descriptionController: _descriptionController,
                  onUploadTap: _uploadNotAvailableYet,
                  onNext: _next,
                ),
                _AlamatStep(
                  formKey: _step2FormKey,
                  labelController: _addressLabelController,
                  picNameController: _addressPicNameController,
                  phoneController: _addressPhoneController,
                  fullAddressController: _addressFullAddressController,
                  cityController: _addressCityController,
                  provinceController: _addressProvinceController,
                  postalCodeController: _addressPostalCodeController,
                  onNext: _next,
                ),
                _VerifikasiStep(
                  storeName: _nameController.text,
                  isSubmitting: _isSubmitting,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;

  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Data Toko', 'Alamat', 'Verifikasi'];
    return Row(
      children: List.generate(labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final passed = (i ~/ 2) < step;
          return Expanded(
            child: Container(height: 2, color: passed ? AppColors.primary : AppColors.divider),
          );
        }
        final index = i ~/ 2;
        final active = index == step;
        final done = index < step;
        return Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: active || done ? AppColors.primary : AppColors.divider,
              child: done
                  ? const Icon(Icons.check, color: AppColors.onPrimary, size: 16)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: active ? AppColors.onPrimary : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[index],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DataTokoStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController slugController;
  final TextEditingController phoneController;
  final TextEditingController descriptionController;
  final VoidCallback onUploadTap;
  final VoidCallback onNext;

  const _DataTokoStep({
    required this.formKey,
    required this.nameController,
    required this.slugController,
    required this.phoneController,
    required this.descriptionController,
    required this.onUploadTap,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: onUploadTap,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 32),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.add, color: AppColors.onPrimary, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(child: Text('Unggah Logo Toko', style: Theme.of(context).textTheme.bodyMedium)),
            const SizedBox(height: AppSpacing.lg),
            AuthTextField(
              label: 'Nama Toko',
              hint: 'Nama tokomu',
              icon: Icons.storefront_outlined,
              controller: nameController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama toko wajib diisi' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'URL Toko',
              hint: 'shopy.id/nama-toko',
              icon: Icons.link_outlined,
              controller: slugController,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'URL toko wajib diisi';
                if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v.trim())) {
                  return 'Hanya huruf kecil, angka, dan tanda -';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Nomor HP Toko',
              hint: '0812-3456-7890',
              icon: Icons.phone_outlined,
              controller: phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nomor HP wajib diisi' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Deskripsi Toko',
              hint: 'Ceritakan tokomu secara singkat',
              icon: Icons.notes_outlined,
              controller: descriptionController,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                child: const Text('Lanjut ke Alamat Toko'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlamatStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController labelController;
  final TextEditingController picNameController;
  final TextEditingController phoneController;
  final TextEditingController fullAddressController;
  final TextEditingController cityController;
  final TextEditingController provinceController;
  final TextEditingController postalCodeController;
  final VoidCallback onNext;

  const _AlamatStep({
    required this.formKey,
    required this.labelController,
    required this.picNameController,
    required this.phoneController,
    required this.fullAddressController,
    required this.cityController,
    required this.provinceController,
    required this.postalCodeController,
    required this.onNext,
  });

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alamat Pickup', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Alamat ini dipakai kurir buat ambil paket dari tokomu',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthTextField(
              label: 'Label Alamat',
              hint: 'Gudang Utama',
              icon: Icons.label_outline,
              controller: labelController,
              validator: (v) => _required(v, 'Label alamat'),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Nama Penanggung Jawab',
              hint: 'Nama lengkap',
              icon: Icons.person_outline,
              controller: picNameController,
              validator: (v) => _required(v, 'Nama penanggung jawab'),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Nomor HP',
              hint: '0812-3456-7890',
              icon: Icons.phone_outlined,
              controller: phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) => _required(v, 'Nomor HP'),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Alamat Lengkap',
              hint: 'Nama jalan, nomor, RT/RW',
              icon: Icons.home_outlined,
              controller: fullAddressController,
              validator: (v) => _required(v, 'Alamat lengkap'),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Kota/Kabupaten',
              hint: 'Jakarta Selatan',
              icon: Icons.location_city_outlined,
              controller: cityController,
              validator: (v) => _required(v, 'Kota/kabupaten'),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Provinsi',
              hint: 'DKI Jakarta',
              icon: Icons.map_outlined,
              controller: provinceController,
              validator: (v) => _required(v, 'Provinsi'),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Kode Pos',
              hint: '12345',
              icon: Icons.markunread_mailbox_outlined,
              controller: postalCodeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: (v) => _required(v, 'Kode pos'),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: onNext, child: const Text('Lanjut ke Verifikasi')),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifikasiStep extends StatelessWidget {
  final String storeName;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _VerifikasiStep({
    required this.storeName,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verifikasi', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Toko "$storeName" siap diajukan.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Upload dokumen verifikasi (KTP/NPWP/NIB) belum tersedia di versi ini — '
                    'bisa dilengkapi nanti lewat halaman Profil Toko begitu fiturnya siap. '
                    'Toko kamu tetap bisa diajukan sekarang dengan status "Menunggu Verifikasi".',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                    )
                  : const Text('Ajukan Toko'),
            ),
          ),
        ],
      ),
    );
  }
}
