enum StoreDocumentType {
  ktp('Ktp', 'KTP'),
  npwp('Npwp', 'NPWP'),
  nib('Nib', 'NIB');

  final String apiValue;
  final String label;

  const StoreDocumentType(this.apiValue, this.label);

  static StoreDocumentType fromApiValue(String value) {
    return StoreDocumentType.values.firstWhere((t) => t.apiValue == value, orElse: () => StoreDocumentType.ktp);
  }
}

enum DocumentReviewStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  final String apiValue;

  const DocumentReviewStatus(this.apiValue);

  static DocumentReviewStatus fromApiValue(String value) {
    return DocumentReviewStatus.values.firstWhere((s) => s.apiValue == value, orElse: () => DocumentReviewStatus.pending);
  }
}

/// Dokumen verifikasi toko (KTP/NPWP/NIB), sesuai `StoreDocumentDto` di backend.
class StoreDocument {
  final String id;
  final StoreDocumentType type;
  final String fileUrl;
  final DocumentReviewStatus status;
  final String? rejectReason;
  final DateTime? reviewedAt;

  const StoreDocument({
    required this.id,
    required this.type,
    required this.fileUrl,
    required this.status,
    this.rejectReason,
    this.reviewedAt,
  });

  factory StoreDocument.fromJson(Map<String, dynamic> json) {
    return StoreDocument(
      id: json['id'] as String,
      type: StoreDocumentType.fromApiValue(json['type'] as String),
      fileUrl: json['fileUrl'] as String,
      status: DocumentReviewStatus.fromApiValue(json['status'] as String),
      rejectReason: json['rejectReason'] as String?,
      reviewedAt: json['reviewedAt'] == null ? null : DateTime.parse(json['reviewedAt'] as String),
    );
  }
}
