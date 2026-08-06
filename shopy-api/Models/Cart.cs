namespace shopy_api.Models;

public class Cart : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid? UserId { get; set; }
    public ApplicationUser? User { get; set; }

    public Guid? GuestId { get; set; }

    public ICollection<CartItem> CartItems { get; set; } = [];

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
