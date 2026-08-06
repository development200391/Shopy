using shopy_api.Models;

namespace shopy_api.Services;

public record AccessTokenResult(string Token, DateTime ExpiresAt);

public interface ITokenService
{
    AccessTokenResult GenerateAccessToken(ApplicationUser user);
    string GenerateRefreshToken();
    DateTime GetRefreshTokenExpiry();
}
