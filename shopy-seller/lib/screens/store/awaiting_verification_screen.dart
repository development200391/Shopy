import 'package:flutter/material.dart';

import '../../models/store/store_summary.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'store_documents_screen.dart';

/// Ditampilkan untuk toko `Pending`/`Rejected` (verifikasi admin — TASKSELLER.md
/// Fase 9) maupun `Suspended`/`Closed` (varian pesan blokir).
class AwaitingVerificationScreen extends StatelessWidget {
  final StoreSummary store;

  const AwaitingVerificationScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final blocked = store.status == StoreStatus.suspended || store.status == StoreStatus.closed;
    final rejected = store.status == StoreStatus.rejected;

    final icon = switch (store.status) {
      StoreStatus.rejected => Icons.cancel_outlined,
      StoreStatus.suspended || StoreStatus.closed => Icons.block_outlined,
      _ => Icons.hourglass_top_outlined,
    };
    final title = switch (store.status) {
      StoreStatus.rejected => 'Verifikasi Ditolak',
      StoreStatus.suspended || StoreStatus.closed => 'Toko Dinonaktifkan',
      _ => 'Menunggu Verifikasi',
    };
    final message = switch (store.status) {
      StoreStatus.rejected =>
        'Pengajuan toko "${store.name}" ditolak tim kami. Lengkapi/perbaiki dokumen di bawah lalu hubungi admin Shopy untuk diajukan ulang.',
      StoreStatus.suspended =>
        'Toko "${store.name}" sedang di-suspend. Hubungi admin Shopy untuk info lebih lanjut.',
      StoreStatus.closed => 'Toko "${store.name}" sudah ditutup.',
      _ =>
        'Toko "${store.name}" sudah diajukan dan sedang ditinjau tim kami. Lengkapi dokumen verifikasi di bawah supaya proses peninjauan lebih cepat.',
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: (blocked || rejected ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: blocked || rejected ? AppColors.error : AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              if ((rejected || blocked) &&
                  store.moderationReason != null &&
                  store.moderationReason!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alasan dari admin',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error),
                      ),
                      const SizedBox(height: 4),
                      Text(store.moderationReason!, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
              if (store.status == StoreStatus.pending || rejected) ...[
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StoreDocumentsScreen()),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Lengkapi Dokumen Verifikasi'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
