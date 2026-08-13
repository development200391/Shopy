import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/seller_provider.dart';
import '../../providers/seller_product_provider.dart';
import '../../services/api_client.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/auth/auth_text_field.dart';

class _PhotoItem {
  // Upload terjadi langsung saat foto dipilih (lihat _addPhotos), jadi tiap
  // item di sini selalu sudah punya URL — tidak ada state "menunggu upload".
  final String url;

  const _PhotoItem({required this.url});
}

/// Dipakai untuk **Tambah** (productId null) maupun **Edit** Produk — desain
/// terpilih: **Bold & Colorful** (lihat `design/assets/produk-form-seller-bold-colorful.png`).
class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormScreen({super.key, this.productId});

  bool get isEdit => productId != null;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _weightController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController(text: '0');

  final List<_PhotoItem> _photos = [];
  String? _categoryId;
  String _condition = 'New';
  bool _isActiveOnSave = true;
  bool _initialized = false;
  bool _uploadingPhoto = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _initFromDetail(dynamic product) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = product.name as String;
    _priceController.text = '${product.price}';
    _weightController.text = '${product.weight}';
    _descriptionController.text = (product.description as String?) ?? '';
    _stockController.text = '${product.stock}';
    _categoryId = product.categoryId as String;
    _condition = product.condition as String;
    for (final image in product.images) {
      _photos.add(_PhotoItem(url: image.url as String));
    }
  }

  Future<void> _addPhotos() async {
    final remaining = 5 - _photos.length;
    if (remaining <= 0) return;

    final picked = await ImagePicker().pickMultiImage(imageQuality: 85, limit: remaining);
    if (picked.isEmpty) return;

    setState(() => _uploadingPhoto = true);
    try {
      for (final file in picked) {
        final url = await ref.read(sellerApiServiceProvider).uploadFile(file.path, 'product');
        if (!mounted) return;
        setState(() => _photos.add(_PhotoItem(url: url)));
      }
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _changeStock(int delta) {
    final current = int.tryParse(_stockController.text) ?? 0;
    final next = (current + delta).clamp(0, 999999);
    setState(() => _stockController.text = '$next');
  }

  Future<void> _submit({required bool publish}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih kategori produk dulu.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = {
        'name': _nameController.text.trim(),
        'categoryId': _categoryId,
        'price': int.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'weight': int.parse(_weightController.text.isEmpty ? '0' : _weightController.text),
        'condition': _condition,
        'description': _descriptionController.text.trim(),
        'imageUrls': _photos.map((p) => p.url).toList(),
        'isActive': publish,
      };

      final api = ref.read(sellerProductApiServiceProvider);
      if (widget.isEdit) {
        await api.updateProduct(widget.productId!, data);
      } else {
        await api.createProduct(data);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    final categoriesAsync = ref.watch(categoryOptionsProvider);
    final detailAsync = widget.isEdit
        ? ref.watch(sellerProductDetailProvider(widget.productId!))
        : null;

    Widget body(List<dynamic> categoryOptions) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Foto Produk (maks. 5)', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              _PhotoPicker(
                photos: _photos,
                uploading: _uploadingPhoto,
                onAdd: _addPhotos,
                onRemove: _removePhoto,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                label: 'Nama Produk',
                hint: 'Nama produk yang dijual',
                icon: Icons.shopping_bag_outlined,
                controller: _nameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama produk wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Kategori', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                isExpanded: true,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.sell_outlined)),
                items: [
                  for (final option in categoryOptions)
                    DropdownMenuItem(value: option.id as String, child: Text(option.label as String)),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                label: 'Harga Satuan',
                hint: '0',
                icon: Icons.payments_outlined,
                controller: _priceController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Harga wajib diisi';
                  if (int.tryParse(v) == null) return 'Harga harus angka';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stok', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            IconButton.filled(
                              onPressed: () => _changeStock(-1),
                              icon: const Icon(Icons.remove),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _stockController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(border: InputBorder.none),
                              ),
                            ),
                            IconButton.filled(
                              onPressed: () => _changeStock(1),
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AuthTextField(
                      label: 'Berat (gram)',
                      hint: '0',
                      icon: Icons.scale_outlined,
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      validator: (v) => (int.tryParse(v ?? '') == null) ? 'Berat harus angka' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                label: 'Deskripsi Produk',
                hint: 'Jelaskan detail produk',
                icon: Icons.notes_outlined,
                controller: _descriptionController,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Kondisi', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Row(
                children: [
                  _ConditionChip(
                    label: 'Baru',
                    selected: _condition == 'New',
                    onTap: () => setState(() => _condition = 'New'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _ConditionChip(
                    label: 'Bekas',
                    selected: _condition == 'Used',
                    onTap: () => setState(() => _condition = 'Used'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tayangkan Produk', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'Produk langsung tampil di katalog',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isActiveOnSave,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => _isActiveOnSave = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => _submit(publish: false),
                      child: const Text('Simpan Draf'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _submit(publish: _isActiveOnSave),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                            )
                          : const Text('Simpan & Tayangkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Ubah Produk' : 'Tambah Produk')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Gagal memuat kategori')),
        data: (categoryOptions) {
          if (!widget.isEdit) {
            return body(categoryOptions);
          }
          return detailAsync!.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const Center(child: Text('Gagal memuat produk')),
            data: (product) {
              _initFromDetail(product);
              return body(categoryOptions);
            },
          );
        },
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final List<_PhotoItem> photos;
  final bool uploading;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _PhotoPicker({
    required this.photos,
    required this.uploading,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < photos.length; i++) _PhotoThumb(index: i, photo: photos[i], onRemove: onRemove),
          if (photos.length < 5)
            GestureDetector(
              onTap: uploading ? null : onAdd,
              child: Container(
                width: 96,
                height: 96,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                alignment: Alignment.center,
                child: uploading
                    ? const CircularProgressIndicator()
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                          SizedBox(height: 4),
                          Text('Tambah', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final int index;
  final _PhotoItem photo;
  final ValueChanged<int> onRemove;

  const _PhotoThumb({required this.index, required this.photo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 96,
              height: 96,
              child: Image.network('${resolveApiBaseUrl()}${photo.url}', fit: BoxFit.cover),
            ),
          ),
          if (index == 0)
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: const Text('Utama', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: () => onRemove(index),
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ConditionChip({required this.label, required this.selected, required this.onTap});

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
