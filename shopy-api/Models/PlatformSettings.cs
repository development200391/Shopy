namespace shopy_api.Models;

/// <summary>
/// Baris tunggal (singleton, <see cref="Id"/> selalu 1) berisi parameter bisnis
/// platform yang bisa diubah admin tanpa redeploy (TASKSELLER.md Fase 9) —
/// menggantikan pembacaan langsung <c>IConfiguration:Platform:*</c> yang
/// sebelumnya statis dari <c>appsettings.json</c>.
/// </summary>
public class PlatformSettings
{
    public int Id { get; set; } = 1;

    public decimal CommissionPercent { get; set; }
    public decimal WithdrawalAdminFee { get; set; }
    public decimal MinWithdrawal { get; set; }
    public int MaxWithdrawalsPerDay { get; set; }
    public int AutoCancelHours { get; set; }
    public int AutoCompleteDays { get; set; }
    public int LowStockThreshold { get; set; }

    public DateTime UpdatedAt { get; set; }
}
