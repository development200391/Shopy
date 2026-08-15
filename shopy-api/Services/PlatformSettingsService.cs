using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Admin;

namespace shopy_api.Services;

/// <summary>
/// Baris singleton <see cref="PlatformSettings"/> (Id=1) — menggantikan pembacaan langsung
/// <c>IConfiguration:Platform:*</c> supaya admin bisa ubah parameter bisnis tanpa redeploy
/// (TASKSELLER.md Fase 9). Baris pertama dibuat dari default <c>appsettings.json</c> yang
/// sudah ada, jadi tidak ada perubahan perilaku sampai admin benar-benar mengubah sesuatu.
/// </summary>
public class PlatformSettingsService(ShopyDbContext dbContext, IConfiguration configuration) : IPlatformSettingsService
{
    public async Task<PlatformSettings> GetAsync()
    {
        var settings = await dbContext.PlatformSettings.SingleOrDefaultAsync(s => s.Id == 1);
        if (settings is not null)
        {
            return settings;
        }

        settings = new PlatformSettings
        {
            Id = 1,
            CommissionPercent = configuration.GetValue("Platform:CommissionPercent", 2m),
            WithdrawalAdminFee = configuration.GetValue("Platform:WithdrawalAdminFee", 2500m),
            MinWithdrawal = configuration.GetValue("Platform:MinWithdrawal", 50000m),
            MaxWithdrawalsPerDay = configuration.GetValue("Platform:MaxWithdrawalsPerDay", 3),
            AutoCancelHours = configuration.GetValue("Platform:AutoCancelHours", 24),
            AutoCompleteDays = configuration.GetValue("Platform:AutoCompleteDays", 3),
            LowStockThreshold = configuration.GetValue("Platform:LowStockThreshold", 10),
            UpdatedAt = DateTime.UtcNow,
        };
        dbContext.PlatformSettings.Add(settings);
        await dbContext.SaveChangesAsync();
        return settings;
    }

    public async Task<PlatformSettings> UpdateAsync(UpdatePlatformSettingsRequest request)
    {
        var settings = await GetAsync();
        settings.CommissionPercent = request.CommissionPercent;
        settings.WithdrawalAdminFee = request.WithdrawalAdminFee;
        settings.MinWithdrawal = request.MinWithdrawal;
        settings.MaxWithdrawalsPerDay = request.MaxWithdrawalsPerDay;
        settings.AutoCancelHours = request.AutoCancelHours;
        settings.AutoCompleteDays = request.AutoCompleteDays;
        settings.LowStockThreshold = request.LowStockThreshold;
        settings.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
        return settings;
    }
}
