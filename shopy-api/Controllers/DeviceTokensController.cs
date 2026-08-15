using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.DeviceTokens;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize]
[Route("api/device-tokens")]
public class DeviceTokensController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Register(RegisterDeviceTokenRequest request)
    {
        var userId = User.GetUserId();
        var now = DateTime.UtcNow;
        var appType = Enum.TryParse<DeviceTokenAppType>(request.AppType, out var parsed) ? parsed : DeviceTokenAppType.Buyer;

        var existing = await dbContext.DeviceTokens.SingleOrDefaultAsync(t => t.Token == request.Token);
        if (existing is not null)
        {
            // Token bisa pindah pemilik (mis. logout lalu login akun lain di device yang sama).
            existing.UserId = userId;
            existing.AppType = appType;
            existing.UpdatedAt = now;
        }
        else
        {
            dbContext.DeviceTokens.Add(new DeviceToken
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Token = request.Token,
                AppType = appType,
                CreatedAt = now,
                UpdatedAt = now,
            });
        }

        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{token}")]
    public async Task<IActionResult> Unregister(string token)
    {
        var userId = User.GetUserId();
        var existing = await dbContext.DeviceTokens.SingleOrDefaultAsync(t => t.Token == token && t.UserId == userId);
        if (existing is not null)
        {
            dbContext.DeviceTokens.Remove(existing);
            await dbContext.SaveChangesAsync();
        }

        return NoContent();
    }
}
