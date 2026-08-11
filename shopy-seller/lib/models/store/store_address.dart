class StoreAddress {
  final String id;
  final String label;
  final String picName;
  final String phoneNumber;
  final String fullAddress;
  final String city;
  final String province;
  final String postalCode;
  final bool isDefault;

  const StoreAddress({
    required this.id,
    required this.label,
    required this.picName,
    required this.phoneNumber,
    required this.fullAddress,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.isDefault,
  });

  StoreAddress copyWith({bool? isDefault}) {
    return StoreAddress(
      id: id,
      label: label,
      picName: picName,
      phoneNumber: phoneNumber,
      fullAddress: fullAddress,
      city: city,
      province: province,
      postalCode: postalCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory StoreAddress.fromJson(Map<String, dynamic> json) {
    return StoreAddress(
      id: json['id'] as String,
      label: json['label'] as String,
      picName: json['picName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      fullAddress: json['fullAddress'] as String,
      city: json['city'] as String,
      province: json['province'] as String,
      postalCode: json['postalCode'] as String,
      isDefault: json['isDefault'] as bool,
    );
  }
}
