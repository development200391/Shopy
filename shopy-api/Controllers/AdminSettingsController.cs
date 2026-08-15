using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using shopy_api.Models;
using shopy_api.Models.Admin;
using shopy_api.Services;

namespace shopy_api.Controllers;

/// <summary>
/// Pengaturan platform (TASKSELLER.md Fase 9) — persentase komisi, biaya admin pencairan,
/// dan ambang stok menipis, sekarang bisa diubah admin tanpa redeploy lewat
/// <see cref="IPlatformSettingsService"/>.
/// </summary>
[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/admin/settings")]
public class AdminSettingsController(IPlatformSettingsService platformSettingsService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PlatformSettingsDto>> GetSettings()
    {
        return Ok(ToDto(await platformSettingsService.GetAsync()));
    }

    [HttpPut]
    public async Task<ActionResult<PlatformSettingsDto>> UpdateSettings(UpdatePlatformSettingsRequest request)
    {
        if (request.CommissionPercent < 0 || request.MaxWithdrawalsPerDay < 1
            || request.AutoCancelHours < 1 || request.AutoCompleteDays < 1 || request.LowStockThreshold < 0)
        {
            return BadRequest(new { message = "Nilai pengaturan tidak valid." });
        }

        return Ok(ToDto(await platformSettingsService.UpdateAsync(request)));
    }

    private static PlatformSettingsDto ToDto(PlatformSettings s) => new(
        s.CommissionPercent, s.WithdrawalAdminFee, s.MinWithdrawal, s.MaxWithdrawalsPerDay,
        s.AutoCancelHours, s.AutoCompleteDays, s.LowStockThreshold, s.UpdatedAt);
}
