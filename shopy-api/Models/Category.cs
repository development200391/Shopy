namespace shopy_api.Models;

public class Category : ISoftDeletable
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }

    public Guid? ParentCategoryId { get; set; }
    public Category? ParentCategory { get; set; }
    public ICollection<Category> ChildCategories { get; set; } = [];

    public ICollection<Product> Products { get; set; } = [];

    public DateTime CreatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
