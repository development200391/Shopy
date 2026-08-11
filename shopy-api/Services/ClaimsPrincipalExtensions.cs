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

    /// <summary>
    /// Ambil Id toko dari claim JWT ("store_id") — null kalau user belum punya toko.
    /// </summary>
    public static Guid? GetStoreId(this ClaimsPrincipal user)
    {
        var raw = user.FindFirstValue("store_id");
        return raw is null ? null : Guid.Parse(raw);
    }
}
