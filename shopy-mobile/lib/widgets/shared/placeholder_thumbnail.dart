import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Placeholder gambar produk (dipakai sampai ada `ImageUrl` produk asli yang
/// bisa di-load, mis. lewat `Image.network`). Tampil sebagai kotak dengan
/// ikon foto bertema oranye — konsisten dengan mockup di folder `design/`.
class PlaceholderThumbnail extends StatelessWidget {
  final double borderRadius;

  const PlaceholderThumbnail({super.key, this.borderRadius = 12});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(Icons.image_outlined, color: AppColors.primary.withValues(alpha: 0.45), size: 28),
      ),
    );
  }
}
