/// Profil publik toko, sesuai `StorePublicProfileDto` di backend — dipakai
/// halaman Profil Toko (dari tombol "Kunjungi Toko" di Detail Produk).
class StorePublicProfile {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? phoneNumber;
  final double ratingAverage;
  final int ratingCount;
  final int productCount;
  final int followerCount;
  final bool isOpen;

  const StorePublicProfile({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.phoneNumber,
    required this.ratingAverage,
    required this.ratingCount,
    required this.productCount,
    required this.followerCount,
    required this.isOpen,
  });

  factory StorePublicProfile.fromJson(Map<String, dynamic> json) {
    return StorePublicProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      ratingAverage: (json['ratingAverage'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      productCount: json['productCount'] as int,
      followerCount: json['followerCount'] as int,
      isOpen: json['isOpen'] as bool,
    );
  }
}
