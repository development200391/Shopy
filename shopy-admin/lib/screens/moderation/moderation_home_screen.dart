import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'product_search_screen.dart';
import 'review_search_screen.dart';

/// Landing tab Moderasi — 2 pintu masuk (Cari Produk / Cari Ulasan), pola sama
/// menu kartu di `_LainnyaTab` (`admin_home_shell.dart`), bukan langsung salah
/// satu halaman search karena keduanya setara pentingnya (TASKADMIN.md Fase 4).
class ModerationHomeScreen extends StatelessWidget {
  const ModerationHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Moderasi')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
            ),
            // Lihat catatan sama di `_LainnyaTab` (`admin_home_shell.dart`):
            // tanpa Material transparan di sini, ripple `ListTile` ketutupan dekorasi.
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                    title: const Text('Cari Produk'),
                    subtitle: const Text('Cari & takedown produk bermasalah di semua toko'),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const ProductSearchScreen())),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.rate_review_outlined, color: AppColors.primary),
                    title: const Text('Cari Ulasan'),
                    subtitle: const Text('Cari & takedown ulasan bermasalah di semua toko'),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const ReviewSearchScreen())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
