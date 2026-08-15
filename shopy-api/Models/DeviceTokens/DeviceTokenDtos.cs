namespace shopy_api.Models.DeviceTokens;

/// <remarks><paramref name="AppType"/>: "Buyer" (default, app pembeli tidak perlu kirim field
/// ini) atau "Seller" — dipakai memisahkan token per-app (TASKSELLER.md Fase 8).</remarks>
public record RegisterDeviceTokenRequest(string Token, string? AppType = null);
