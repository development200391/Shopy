namespace shopy_api.Models.Admin;

public record PlatformSettingsDto(
    decimal CommissionPercent,
    decimal WithdrawalAdminFee,
    decimal MinWithdrawal,
    int MaxWithdrawalsPerDay,
    int AutoCancelHours,
    int AutoCompleteDays,
    int LowStockThreshold,
    DateTime UpdatedAt);

public record UpdatePlatformSettingsRequest(
    decimal CommissionPercent,
    decimal WithdrawalAdminFee,
    decimal MinWithdrawal,
    int MaxWithdrawalsPerDay,
    int AutoCancelHours,
    int AutoCompleteDays,
    int LowStockThreshold);
