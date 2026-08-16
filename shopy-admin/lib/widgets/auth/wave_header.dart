import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Header login. Sengaja memakai `AppColors.secondary` (navy), BUKAN `primary`
/// (oranye) seperti versi `shopy-seller` yang jadi asalnya — navy adalah warna
/// identitas app admin, sama seperti splash, app icon, dan indikator bottom nav.
/// Logonya juga logo asli (`assets/logo.svg`), bukan huruf "S" tiruan.
class WaveHeader extends StatelessWidget {
  final double height;

  const WaveHeader({super.key, this.height = 300});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        width: double.infinity,
        height: height,
        color: AppColors.secondary,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.onPrimary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset('assets/logo.svg'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Shopy Admin',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Verifikasi & kelola platform Shopy',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 36);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 18);
    path.quadraticBezierTo(size.width * 0.75, size.height - 36, size.width, size.height - 8);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
