import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/order/courier.dart';
import '../../providers/seller_order_provider.dart';
import '../../providers/seller_provider.dart';
import '../../services/api_client.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Halaman **Kirim Pesanan** — desain terpilih: **Bold & Colorful**
/// (lihat `design/assets/kirim-pesanan-seller-bold-colorful.png`).
class ShipOrderScreen extends ConsumerStatefulWidget {
  final String orderId;

  const ShipOrderScreen({super.key, required this.orderId});

  @override
  ConsumerState<ShipOrderScreen> createState() => _ShipOrderScreenState();
}

class _ShipOrderScreenState extends ConsumerState<ShipOrderScreen> {
  Courier _courier = kCouriers.first;
  final _trackingController = TextEditingController();
  String? _proofPhotoUrl;
  bool _uploadingPhoto = false;
  bool _confirmed = false;
  bool _submitting = false;

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  void _notAvailableYet() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fitur ini belum tersedia.')));
  }

  Future<void> _pickProofPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref.read(sellerApiServiceProvider).uploadFile(picked.path, 'proof');
      if (!mounted) return;
      setState(() => _proofPhotoUrl = url);
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _submit() async {
    if (_trackingController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nomor resi wajib diisi.')));
      return;
    }
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi dulu kalau paket sudah diserahkan ke kurir.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(sellerOrderApiServiceProvider)
          .ship(
            widget.orderId,
            courierCode: _courier.code,
            courierService: _courier.service,
            trackingNumber: _trackingController.text.trim(),
            proofPhotoUrl: _proofPhotoUrl,
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kirim Pesanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Kurir', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            RadioGroup<Courier>(
              groupValue: _courier,
              onChanged: (value) => setState(() => _courier = value ?? _courier),
              child: Column(
                children: [
                  for (final courier in kCouriers) ...[
                    _CourierTile(
                      courier: courier,
                      selected: _courier == courier,
                      onTap: () => setState(() => _courier = courier),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Nomor Resi', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            TextField(
              controller: _trackingController,
              decoration: InputDecoration(
                hintText: 'Masukkan nomor resi',
                suffixIcon: TextButton.icon(
                  onPressed: _notAvailableYet,
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Scan'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Foto Bukti Serah Terima (opsional)', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            _ProofPhotoBox(
              url: _proofPhotoUrl,
              uploading: _uploadingPhoto,
              onTap: _pickProofPhoto,
              onRemove: () => setState(() => _proofPhotoUrl = null),
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text('Paket sudah saya serahkan ke kurir'),
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Status berubah jadi "Dikirim". Pembeli otomatis dapat notifikasi + nomor resi.',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                  )
                : const Icon(Icons.local_shipping_outlined),
            label: const Text('Kirim & Simpan Resi'),
          ),
        ),
      ),
    );
  }
}

class _CourierTile extends StatelessWidget {
  final Courier courier;
  final bool selected;
  final VoidCallback onTap;

  const _CourierTile({required this.courier, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(courier.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'Estimasi ${courier.eta}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              'Rp${courier.price}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: AppSpacing.sm),
            Radio<Courier>(value: courier, activeColor: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _ProofPhotoBox extends StatelessWidget {
  final String? url;
  final bool uploading;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ProofPhotoBox({
    required this.url,
    required this.uploading,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (url != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              '${resolveApiBaseUrl()}$url',
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: uploading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 28),
                  SizedBox(height: 4),
                  Text('Ambil / unggah foto paket', style: TextStyle(color: AppColors.primary)),
                ],
              ),
      ),
    );
  }
}
