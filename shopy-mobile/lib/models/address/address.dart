/// Alamat pengiriman milik user, sesuai `AddressDto` di backend.
class Address {
  final String id;
  final String label;
  final String recipientName;
  final String phoneNumber;
  final String fullAddress;
  final String city;
  final String province;
  final String postalCode;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phoneNumber,
    required this.fullAddress,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      label: json['label'] as String,
      recipientName: json['recipientName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      fullAddress: json['fullAddress'] as String,
      city: json['city'] as String,
      province: json['province'] as String,
      postalCode: json['postalCode'] as String,
      isDefault: json['isDefault'] as bool,
    );
  }

  Address copyWith({bool? isDefault}) {
    return Address(
      id: id,
      label: label,
      recipientName: recipientName,
      phoneNumber: phoneNumber,
      fullAddress: fullAddress,
      city: city,
      province: province,
      postalCode: postalCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
