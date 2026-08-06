namespace shopy_api.Models;

public class PasswordResetCode : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    // SHA-256 hash dari kode OTP 6 digit, bukan plaintext.
    public string CodeHash { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime? UsedAt { get; set; }

    public bool IsActive => UsedAt is null && DateTime.UtcNow < ExpiresAt;

    public DateTime CreatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
