namespace shopy_api.Models;

public class FlashSaleItem : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid FlashSaleId { get; set; }
    public FlashSale FlashSale { get; set; } = null!;

    public Guid ProductId { get; set; }
    public Product Product { get; set; } = null!;

    public decimal SpecialPrice { get; set; }
    public int Quota { get; set; }
    public int SoldCount { get; set; }

    public bool IsDeleted { get; set; }
}
