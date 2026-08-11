import 'store_summary.dart';

class SellerMe {
  final String userId;
  final String email;
  final String fullName;
  final StoreSummary? store;

  const SellerMe({
    required this.userId,
    required this.email,
    required this.fullName,
    this.store,
  });

  factory SellerMe.fromJson(Map<String, dynamic> json) {
    final storeJson = json['store'] as Map<String, dynamic>?;
    return SellerMe(
      userId: json['userId'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      store: storeJson == null ? null : StoreSummary.fromJson(storeJson),
    );
  }
}
