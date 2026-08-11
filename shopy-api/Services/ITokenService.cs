using shopy_api.Models;

namespace shopy_api.Services;

public record AccessTokenResult(string Token, DateTime ExpiresAt);

public interface ITokenService
{
    Task<AccessTokenResult> GenerateAccessTokenAsync(ApplicationUser user);
    string GenerateRefreshToken();
    DateTime GetRefreshTokenExpiry();
}
