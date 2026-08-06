using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace shopy_api.Services;

public class FacebookAuthService(IHttpClientFactory httpClientFactory, IConfiguration configuration)
    : IFacebookAuthService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    public async Task<FacebookProfile> VerifyAccessTokenAsync(string accessToken)
    {
        var appId = configuration["Authentication:Facebook:AppId"];
        var appSecret = configuration["Authentication:Facebook:AppSecret"];
        if (string.IsNullOrEmpty(appId) || string.IsNullOrEmpty(appSecret))
        {
            throw new InvalidOperationException(
                "Konfigurasi Authentication:Facebook:AppId/AppSecret belum diisi.");
        }

        var client = httpClientFactory.CreateClient();

        try
        {
            // Verifikasi token benar-benar diterbitkan untuk app Facebook kita sendiri,
            // supaya token dari app lain tidak bisa dipakai untuk impersonate user di sini.
            var debugUrl = "https://graph.facebook.com/debug_token"
                + $"?input_token={Uri.EscapeDataString(accessToken)}"
                + $"&access_token={Uri.EscapeDataString(appId)}|{Uri.EscapeDataString(appSecret)}";
            var debug = await client.GetFromJsonAsync<FacebookDebugTokenResponse>(debugUrl, JsonOptions)
                ?? throw new UnauthorizedAccessException("Gagal memverifikasi token Facebook.");

            if (!debug.Data.IsValid || !string.Equals(debug.Data.AppId, appId, StringComparison.Ordinal))
            {
                throw new UnauthorizedAccessException("Token Facebook tidak valid untuk aplikasi ini.");
            }

            var profileUrl = "https://graph.facebook.com/me"
                + $"?fields=id,name,email&access_token={Uri.EscapeDataString(accessToken)}";
            var profile = await client.GetFromJsonAsync<FacebookProfile>(profileUrl, JsonOptions)
                ?? throw new UnauthorizedAccessException("Gagal mengambil profil Facebook.");

            return profile;
        }
        catch (HttpRequestException)
        {
            // Termasuk kasus App ID/Secret salah (Graph API balas 4xx) — dari sisi client,
            // itu sama-sama berarti login via Facebook gagal.
            throw new UnauthorizedAccessException("Gagal memverifikasi token Facebook.");
        }
    }

    private class FacebookDebugTokenResponse
    {
        public FacebookDebugTokenData Data { get; set; } = new();
    }

    private class FacebookDebugTokenData
    {
        [JsonPropertyName("is_valid")]
        public bool IsValid { get; set; }

        [JsonPropertyName("app_id")]
        public string? AppId { get; set; }
    }
}
