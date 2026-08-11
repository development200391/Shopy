import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/seller_provider.dart';
import '../../providers/store_settings_provider.dart';
import '../../services/api_client.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/auth/auth_text_field.dart';

class EditStoreProfileScreen extends ConsumerStatefulWidget {
  const EditStoreProfileScreen({super.key});

  @override
  ConsumerState<EditStoreProfileScreen> createState() => _EditStoreProfileScreenState();
}

class _EditStoreProfileScreenState extends ConsumerState<EditStoreProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _logoUrl;
  String? _bannerUrl;
  bool _initialized = false;
  bool _uploadingLogo = false;
  bool _uploadingBanner = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initFrom(dynamic store) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = store.name as String;
    _descriptionController.text = (store.description as String?) ?? '';
    _phoneController.text = (store.phoneNumber as String?) ?? '';
    _logoUrl = store.logoUrl as String?;
    _bannerUrl = store.bannerUrl as String?;
  }

  Future<void> _pickAndUpload({required bool isLogo}) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => isLogo ? _uploadingLogo = true : _uploadingBanner = true);
    try {
      final url = await ref
          .read(sellerApiServiceProvider)
          .uploadFile(picked.path, isLogo ? 'logo' : 'banner');
      setState(() => isLogo ? _logoUrl = url : _bannerUrl = url);
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => isLogo ? _uploadingLogo = false : _uploadingBanner = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(sellerApiServiceProvider)
          .updateStore(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            logoUrl: _logoUrl,
            bannerUrl: _bannerUrl,
            phoneNumber: _phoneController.text.trim(),
          );
      ref.invalidate(storeDetailProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil toko disimpan.')));
      Navigator.of(context).pop();
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(storeDetailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil Toko')),
      body: storeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Gagal memuat data toko')),
        data: (store) {
          _initFrom(store);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ImagePickerField(
                    label: 'Logo Toko',
                    url: _logoUrl,
                    uploading: _uploadingLogo,
                    circle: true,
                    onTap: () => _pickAndUpload(isLogo: true),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ImagePickerField(
                    label: 'Banner Toko',
                    url: _bannerUrl,
                    uploading: _uploadingBanner,
                    circle: false,
                    onTap: () => _pickAndUpload(isLogo: false),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthTextField(
                    label: 'Nama Toko',
                    hint: 'Nama tokomu',
                    icon: Icons.storefront_outlined,
                    controller: _nameController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama toko wajib diisi' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    label: 'Deskripsi Toko',
                    hint: 'Ceritakan tokomu secara singkat',
                    icon: Icons.notes_outlined,
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    label: 'Nomor HP Toko',
                    hint: '0812-3456-7890',
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
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
            ),
          );
        },
      ),
    );
  }
}

class _ImagePickerField extends StatelessWidget {
  final String label;
  final String? url;
  final bool uploading;
  final bool circle;
  final VoidCallback onTap;

  const _ImagePickerField({
    required this.label,
    required this.url,
    required this.uploading,
    required this.circle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = url == null
        ? null
        : DecorationImage(image: NetworkImage('${resolveApiBaseUrl()}$url'), fit: BoxFit.cover);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: uploading ? null : onTap,
          child: Container(
            width: circle ? 96 : double.infinity,
            height: circle ? 96 : 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(circle ? 48 : 12),
              image: image,
            ),
            alignment: Alignment.center,
            child: uploading
                ? const CircularProgressIndicator()
                : (url == null
                      ? const Icon(Icons.add_a_photo_outlined, color: AppColors.primary)
                      : null),
          ),
        ),
      ],
    );
  }
}
