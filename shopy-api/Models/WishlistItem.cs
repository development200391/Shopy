namespace shopy_api.Models;

public class WishlistItem : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    public Guid ProductId { get; set; }
    public Product Product { get; set; } = null!;

    public DateTime CreatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
