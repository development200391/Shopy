namespace shopy_api.Models;

public class StoreFollower : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid StoreId { get; set; }
    public Store Store { get; set; } = null!;

    public Guid UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    public DateTime CreatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
