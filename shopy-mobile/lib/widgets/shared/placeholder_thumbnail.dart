import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../theme/app_colors.dart';

/// Menampilkan foto produk asli, dengan fallback ke [PlaceholderThumbnail]
/// kalau URL-nya kosong atau gambarnya gagal dimuat.
///
/// Backend menyimpan `ImageUrl` sebagai path RELATIF (mis.
/// `/uploads/product/abc.jpg`), jadi harus diawali `resolveApiBaseUrl()` dulu —
/// `Image.network` tidak bisa memuat path relatif. Pola prefix ini sama seperti
/// yang sudah dipakai di layar chat, ulasan, dan banner toko.
class ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double borderRadius;
  final BoxFit fit;

  const ProductThumbnail({
    super.key,
    required this.imageUrl,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return PlaceholderThumbnail(borderRadius: borderRadius);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url.startsWith('http') ? url : '${resolveApiBaseUrl()}$url',
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            PlaceholderThumbnail(borderRadius: borderRadius),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : PlaceholderThumbnail(borderRadius: borderRadius),
      ),
    );
  }
}

/// Placeholder gambar produk — dipakai [ProductThumbnail] sebagai fallback saat
/// produk belum punya foto atau fotonya gagal dimuat. Tampil sebagai kotak
/// dengan ikon foto bertema oranye, konsisten dengan mockup di folder `design/`.
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
