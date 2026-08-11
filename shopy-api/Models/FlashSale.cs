namespace shopy_api.Models;

public class FlashSale : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid StoreId { get; set; }
    public Store Store { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public DateTime StartAt { get; set; }
    public DateTime EndAt { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<FlashSaleItem> Items { get; set; } = [];

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
