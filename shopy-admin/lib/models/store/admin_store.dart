enum AdminStoreStatus { pending, active, suspended, closed, rejected }

AdminStoreStatus parseAdminStoreStatus(String raw) {
  switch (raw) {
    case 'Active':
      return AdminStoreStatus.active;
    case 'Suspended':
      return AdminStoreStatus.suspended;
    case 'Closed':
      return AdminStoreStatus.closed;
    case 'Rejected':
      return AdminStoreStatus.rejected;
    case 'Pending':
    default:
      return AdminStoreStatus.pending;
  }
}

extension AdminStoreStatusX on AdminStoreStatus {
  /// Nilai yang dikirim ke `?status=` — cocok persis string enum backend.
  String get apiValue => switch (this) {
    AdminStoreStatus.pending => 'Pending',
    AdminStoreStatus.active => 'Active',
    AdminStoreStatus.suspended => 'Suspended',
    AdminStoreStatus.closed => 'Closed',
    AdminStoreStatus.rejected => 'Rejected',
  };

  String get label => switch (this) {
    AdminStoreStatus.pending => 'Menunggu',
    AdminStoreStatus.active => 'Aktif',
    AdminStoreStatus.suspended => 'Ditangguhkan',
    AdminStoreStatus.closed => 'Ditutup',
    AdminStoreStatus.rejected => 'Ditolak',
  };
}

class AdminStoreListItem {
  final String id;
  final String name;
  final String slug;
  final String ownerName;
  final String ownerEmail;
  final AdminStoreStatus status;
  final String? moderationReason;
  final int productCount;
  final DateTime createdAt;

  const AdminStoreListItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.ownerName,
    required this.ownerEmail,
    required this.status,
    this.moderationReason,
    required this.productCount,
    required this.createdAt,
  });

  factory AdminStoreListItem.fromJson(Map<String, dynamic> json) {
    return AdminStoreListItem(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      ownerName: json['ownerName'] as String,
      ownerEmail: json['ownerEmail'] as String,
      status: parseAdminStoreStatus(json['status'] as String),
      moderationReason: json['moderationReason'] as String?,
      productCount: json['productCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AdminStoreDocument {
  final String id;
  final String type;
  final String fileUrl;
  final String status;
  final String? rejectReason;
  final DateTime? reviewedAt;

  const AdminStoreDocument({
    required this.id,
    required this.type,
    required this.fileUrl,
    required this.status,
    this.rejectReason,
    this.reviewedAt,
  });

  factory AdminStoreDocument.fromJson(Map<String, dynamic> json) {
    return AdminStoreDocument(
      id: json['id'] as String,
      type: json['type'] as String,
      fileUrl: json['fileUrl'] as String,
      status: json['status'] as String,
      rejectReason: json['rejectReason'] as String?,
      reviewedAt: json['reviewedAt'] == null ? null : DateTime.parse(json['reviewedAt'] as String),
    );
  }
}

class AdminStoreDetail {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? phoneNumber;
  final String ownerName;
  final String ownerEmail;
  final AdminStoreStatus status;
  final String? moderationReason;
  final double ratingAverage;
  final int ratingCount;
  final int productCount;
  final int followerCount;
  final DateTime createdAt;
  final List<AdminStoreDocument> documents;

  const AdminStoreDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.phoneNumber,
    required this.ownerName,
    required this.ownerEmail,
    required this.status,
    this.moderationReason,
    required this.ratingAverage,
    required this.ratingCount,
    required this.productCount,
    required this.followerCount,
    required this.createdAt,
    required this.documents,
  });

  factory AdminStoreDetail.fromJson(Map<String, dynamic> json) {
    return AdminStoreDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      ownerName: json['ownerName'] as String,
      ownerEmail: json['ownerEmail'] as String,
      status: parseAdminStoreStatus(json['status'] as String),
      moderationReason: json['moderationReason'] as String?,
      ratingAverage: (json['ratingAverage'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      productCount: json['productCount'] as int,
      followerCount: json['followerCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      documents: (json['documents'] as List)
          .map((e) => AdminStoreDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
