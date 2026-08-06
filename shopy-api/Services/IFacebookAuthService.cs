namespace shopy_api.Services;

public record FacebookProfile(string Id, string? Email, string Name);

public interface IFacebookAuthService
{
    Task<FacebookProfile> VerifyAccessTokenAsync(string accessToken);
}
