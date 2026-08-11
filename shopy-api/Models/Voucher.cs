namespace shopy_api.Models;

public class Voucher : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid StoreId { get; set; }
    public Store Store { get; set; } = null!;

    public string Code { get; set; } = string.Empty;
    public VoucherType Type { get; set; }
    public decimal Value { get; set; }
    public decimal? MaxDiscount { get; set; }
    public decimal? MinPurchase { get; set; }

    public int? Quota { get; set; }
    public int UsedCount { get; set; }

    public DateTime StartAt { get; set; }
    public DateTime EndAt { get; set; }
    public bool IsActive { get; set; } = true;

    public bool IsDeleted { get; set; }
}
