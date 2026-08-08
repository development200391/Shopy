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

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
