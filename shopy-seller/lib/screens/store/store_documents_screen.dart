import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/store/store_document.dart';
import '../../providers/seller_document_provider.dart';
import '../../providers/seller_provider.dart';
import '../../services/api_client.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Halaman upload dokumen verifikasi toko (KTP/NPWP/NIB) — TASKADMIN.md Fase 2.
/// Diakses dari `AwaitingVerificationScreen` (toko `Pending`/`Rejected`).
class StoreDocumentsScreen extends ConsumerStatefulWidget {
  const StoreDocumentsScreen({super.key});

  @override
  ConsumerState<StoreDocumentsScreen> createState() => _StoreDocumentsScreenState();
}

class _StoreDocumentsScreenState extends ConsumerState<StoreDocumentsScreen> {
  StoreDocumentType? _uploadingType;

  Future<void> _upload(StoreDocumentType type) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingType = type);
    try {
      final url = await ref.read(sellerApiServiceProvider).uploadFile(picked.path, 'document');
      await ref.read(sellerDocumentApiServiceProvider).createDocument(type: type, fileUrl: url);
      ref.invalidate(sellerDocumentsProvider);
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _uploadingType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(sellerDocumentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dokumen Verifikasi')),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gagal memuat dokumen', style: TextStyle(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => ref.invalidate(sellerDocumentsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (documents) {
          // Ambil yang paling baru per jenis (list sudah terurut terbaru dulu dari backend).
          final latestByType = <StoreDocumentType, StoreDocument>{};
          for (final doc in documents) {
            latestByType.putIfAbsent(doc.type, () => doc);
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const Text(
                'Unggah KTP, NPWP, dan NIB (kalau ada) buat mempercepat proses verifikasi toko oleh admin.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final type in StoreDocumentType.values)
                _DocumentCard(
                  type: type,
                  document: latestByType[type],
                  uploading: _uploadingType == type,
                  onUpload: () => _upload(type),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final StoreDocumentType type;
  final StoreDocument? document;
  final bool uploading;
  final VoidCallback onUpload;

  const _DocumentCard({
    required this.type,
    required this.document,
    required this.uploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: document == null
                  ? Container(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      alignment: Alignment.center,
                      child: const Icon(Icons.description_outlined, color: AppColors.primary),
                    )
                  : Image.network('${resolveApiBaseUrl()}${document!.fileUrl}', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                if (document == null)
                  const Text('Belum diunggah', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
                else ...[
                  _StatusBadge(status: document!.status),
                  if (document!.status == DocumentReviewStatus.rejected &&
                      document!.rejectReason != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      document!.rejectReason!,
                      style: const TextStyle(color: AppColors.error, fontSize: 11),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          uploading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(
                  onPressed: onUpload,
                  child: Text(document == null ? 'Unggah' : 'Ganti'),
                ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DocumentReviewStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      DocumentReviewStatus.pending => (AppColors.warning, 'Menunggu ditinjau'),
      DocumentReviewStatus.approved => (AppColors.success, 'Disetujui'),
      DocumentReviewStatus.rejected => (AppColors.error, 'Ditolak'),
    };
    return Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600));
  }
}
