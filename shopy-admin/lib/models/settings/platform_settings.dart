/// Sesuai `PlatformSettingsDto` di backend.
class PlatformSettings {
  final double commissionPercent;
  final int withdrawalAdminFee;
  final int minWithdrawal;
  final int maxWithdrawalsPerDay;
  final int autoCancelHours;
  final int autoCompleteDays;
  final int lowStockThreshold;
  final DateTime updatedAt;

  const PlatformSettings({
    required this.commissionPercent,
    required this.withdrawalAdminFee,
    required this.minWithdrawal,
    required this.maxWithdrawalsPerDay,
    required this.autoCancelHours,
    required this.autoCompleteDays,
    required this.lowStockThreshold,
    required this.updatedAt,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      commissionPercent: (json['commissionPercent'] as num).toDouble(),
      withdrawalAdminFee: (json['withdrawalAdminFee'] as num).round(),
      minWithdrawal: (json['minWithdrawal'] as num).round(),
      maxWithdrawalsPerDay: json['maxWithdrawalsPerDay'] as int,
      autoCancelHours: json['autoCancelHours'] as int,
      autoCompleteDays: json['autoCompleteDays'] as int,
      lowStockThreshold: json['lowStockThreshold'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
