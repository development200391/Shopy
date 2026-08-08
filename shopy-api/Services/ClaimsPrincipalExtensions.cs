using System.Security.Claims;

namespace shopy_api.Services;

public static class ClaimsPrincipalExtensions
{
    /// <summary>
    /// Ambil Id user dari claim JWT ("sub", di-map otomatis ke <see cref="ClaimTypes.NameIdentifier"/>).
    /// Cuma dipanggil dari endpoint ber-<c>[Authorize]</c>, jadi claim-nya selalu ada & valid.
    /// </summary>
    public static Guid GetUserId(this ClaimsPrincipal user)
    {
        var raw = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue("sub");
        return Guid.Parse(raw!);
    }
}
