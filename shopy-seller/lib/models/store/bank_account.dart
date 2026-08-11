class BankAccount {
  final String id;
  final String bankCode;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final bool isVerified;
  final bool isDefault;

  const BankAccount({
    required this.id,
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    required this.isVerified,
    required this.isDefault,
  });

  BankAccount copyWith({bool? isDefault}) {
    return BankAccount(
      id: id,
      bankCode: bankCode,
      bankName: bankName,
      accountNumber: accountNumber,
      accountHolderName: accountHolderName,
      isVerified: isVerified,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      bankCode: json['bankCode'] as String,
      bankName: json['bankName'] as String,
      accountNumber: json['accountNumber'] as String,
      accountHolderName: json['accountHolderName'] as String,
      isVerified: json['isVerified'] as bool,
      isDefault: json['isDefault'] as bool,
    );
  }
}
