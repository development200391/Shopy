namespace shopy_api.Models;

public class Product : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid StoreId { get; set; }
    public Store Store { get; set; } = null!;

    public Guid CategoryId { get; set; }
    public Category Category { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public int Stock { get; set; }
    // Cache gambar utama — dipertahankan untuk kompatibilitas, sumber gambar lengkap ada di ProductImages.
    public string? ImageUrl { get; set; }

    public int Weight { get; set; }
    public ProductCondition Condition { get; set; } = ProductCondition.New;
    public int SoldCount { get; set; }
    public int ViewCount { get; set; }
    public decimal? DiscountPrice { get; set; }
    public DateTime? DiscountStartAt { get; set; }
    public DateTime? DiscountEndAt { get; set; }

    public decimal RatingAverage { get; set; }
    public int RatingCount { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<ProductImage> Images { get; set; } = [];
    public ICollection<Review> Reviews { get; set; } = [];
    public ICollection<CartItem> CartItems { get; set; } = [];
    public ICollection<OrderItem> OrderItems { get; set; } = [];

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
