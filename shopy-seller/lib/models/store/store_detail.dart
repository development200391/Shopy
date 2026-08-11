import 'store_summary.dart';

class StoreDetail {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? phoneNumber;
  final StoreStatus status;
  final bool isOpen;
  final double ratingAverage;
  final int ratingCount;
  final int productCount;
  final int followerCount;

  const StoreDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.phoneNumber,
    required this.status,
    required this.isOpen,
    required this.ratingAverage,
    required this.ratingCount,
    required this.productCount,
    required this.followerCount,
  });

  factory StoreDetail.fromJson(Map<String, dynamic> json) {
    return StoreDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      status: parseStoreStatus(json['status'] as String),
      isOpen: json['isOpen'] as bool,
      ratingAverage: (json['ratingAverage'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      productCount: json['productCount'] as int,
      followerCount: json['followerCount'] as int,
    );
  }
}
