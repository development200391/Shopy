import 'package:flutter/material.dart';

import '../../models/store/store_summary.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Ditampilkan untuk toko `Pending` (menunggu verifikasi admin — Fase 9) maupun
/// `Suspended`/`Closed` (varian pesan blokir, lihat [StoreSummary.status]).
class AwaitingVerificationScreen extends StatelessWidget {
  final StoreSummary store;

  const AwaitingVerificationScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final blocked = store.status == StoreStatus.suspended || store.status == StoreStatus.closed;

    final icon = blocked ? Icons.block_outlined : Icons.hourglass_top_outlined;
    final title = blocked ? 'Toko Dinonaktifkan' : 'Menunggu Verifikasi';
    final message = switch (store.status) {
      StoreStatus.suspended =>
        'Toko "${store.name}" sedang di-suspend. Hubungi admin Shopy untuk info lebih lanjut.',
      StoreStatus.closed => 'Toko "${store.name}" sudah ditutup.',
      _ =>
        'Toko "${store.name}" sudah diajukan dan sedang ditinjau tim kami. '
            'Verifikasi dokumen (KTP/NPWP/NIB) bisa dilengkapi lewat halaman Profil Toko begitu tersedia.',
    };

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: (blocked ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: blocked ? AppColors.error : AppColors.primary),
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
            ],
          ),
        ),
      ),
    );
  }
}
