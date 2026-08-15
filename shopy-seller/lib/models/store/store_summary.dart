enum StoreStatus { pending, active, suspended, closed, rejected }

StoreStatus parseStoreStatus(String raw) {
  switch (raw) {
    case 'Active':
      return StoreStatus.active;
    case 'Suspended':
      return StoreStatus.suspended;
    case 'Closed':
      return StoreStatus.closed;
    case 'Rejected':
      return StoreStatus.rejected;
    case 'Pending':
    default:
      return StoreStatus.pending;
  }
}

class StoreSummary {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? phoneNumber;
  final StoreStatus status;
  final bool isOpen;
  final String? moderationReason;

  const StoreSummary({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.phoneNumber,
    required this.status,
    required this.isOpen,
    this.moderationReason,
  });

  factory StoreSummary.fromJson(Map<String, dynamic> json) {
    return StoreSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      status: parseStoreStatus(json['status'] as String),
      isOpen: json['isOpen'] as bool,
      moderationReason: json['moderationReason'] as String?,
    );
  }
}
