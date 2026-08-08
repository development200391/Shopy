namespace shopy_api.Models;

public class Notification : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    public NotificationType Type { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;

    // Target opsional buat deep-link, mis. notifikasi status pesanan -> detail pesanan.
    public Guid? OrderId { get; set; }
    public Order? Order { get; set; }

    public bool IsRead { get; set; }

    public DateTime CreatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
