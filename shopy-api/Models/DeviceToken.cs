namespace shopy_api.Models;

/// <summary>
/// Token registrasi Firebase Cloud Messaging milik 1 device. Satu user bisa
/// punya banyak device token (login di beberapa HP).
/// </summary>
public class DeviceToken
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    public string Token { get; set; } = string.Empty;

    // Buyer vs Seller app (TASKSELLER.md Fase 8) — token yang sama nilainya tidak mungkin
    // terdaftar di 2 app fisik berbeda, tapi field ini yang dipakai buat filter "kirim push
    // seller-only" tanpa ikut mengirim ke device app pembeli kalau 1 akun login di keduanya.
    public DeviceTokenAppType AppType { get; set; } = DeviceTokenAppType.Buyer;

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
