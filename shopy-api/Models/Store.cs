namespace shopy_api.Models;

public class Store : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid OwnerUserId { get; set; }
    public ApplicationUser OwnerUser { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? LogoUrl { get; set; }
    public string? BannerUrl { get; set; }
    public string? PhoneNumber { get; set; }

    public StoreStatus Status { get; set; } = StoreStatus.Pending;
    // Diisi admin saat reject/suspend (TASKSELLER.md Fase 9), dikosongkan lagi saat activate.
    public string? ModerationReason { get; set; }
    public bool IsOpen { get; set; } = true;

    public decimal RatingAverage { get; set; }
    public int RatingCount { get; set; }
    public int ProductCount { get; set; }
    public int FollowerCount { get; set; }

    public ICollection<Product> Products { get; set; } = [];
    public ICollection<StoreAddress> Addresses { get; set; } = [];
    public ICollection<StoreDocument> Documents { get; set; } = [];

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
