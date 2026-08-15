using shopy_api.Models;
using shopy_api.Models.Admin;

namespace shopy_api.Services;

public interface IPlatformSettingsService
{
    Task<PlatformSettings> GetAsync();

    Task<PlatformSettings> UpdateAsync(UpdatePlatformSettingsRequest request);
}
