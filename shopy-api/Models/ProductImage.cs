namespace shopy_api.Models;

public class ProductImage : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid ProductId { get; set; }
    public Product Product { get; set; } = null!;

    public string Url { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public bool IsPrimary { get; set; }

    public bool IsDeleted { get; set; }
}
