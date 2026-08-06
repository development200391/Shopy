using Microsoft.AspNetCore.Identity;

namespace shopy_api.Models;

public class ApplicationUser : IdentityUser<Guid>, ISoftDeletable
{
    public string FullName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public DateTime CreatedAt { get; set; }
    public bool IsDeleted { get; set; }

    public ICollection<Address> Addresses { get; set; } = [];
    public ICollection<Order> Orders { get; set; } = [];
    public ICollection<Review> Reviews { get; set; } = [];
}
