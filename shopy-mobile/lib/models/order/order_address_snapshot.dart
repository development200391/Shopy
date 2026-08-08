/// Snapshot alamat pengiriman saat checkout — disalin dari `Address` supaya
/// histori pesanan tidak berubah walau alamat aslinya diedit/dihapus belakangan.
class OrderAddressSnapshot {
  final String recipientName;
  final String phoneNumber;
  final String fullAddress;
  final String city;
  final String province;
  final String postalCode;

  const OrderAddressSnapshot({
    required this.recipientName,
    required this.phoneNumber,
    required this.fullAddress,
    required this.city,
    required this.province,
    required this.postalCode,
  });

  factory OrderAddressSnapshot.fromJson(Map<String, dynamic> json) {
    return OrderAddressSnapshot(
      recipientName: json['recipientName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      fullAddress: json['fullAddress'] as String,
      city: json['city'] as String,
      province: json['province'] as String,
      postalCode: json['postalCode'] as String,
    );
  }
}
