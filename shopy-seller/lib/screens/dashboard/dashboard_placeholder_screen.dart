import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/store/store_summary.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Placeholder — diganti dashboard asli begitu Fase 8 (TASKSELLER.md) dikerjakan,
/// pola sama seperti Home placeholder di `shopy-mobile` Fase 1.
class DashboardPlaceholderScreen extends StatelessWidget {
  final StoreSummary store;

  const DashboardPlaceholderScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/logo.svg', width: 72, height: 72),
              const SizedBox(height: AppSpacing.lg),
              Text(store.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Toko kamu aktif. Dashboard lengkap menyusul.',
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
