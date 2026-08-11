namespace shopy_api.Models;

/// <summary>Catatan pemakaian voucher — immutable, tidak ada soft-delete.</summary>
public class VoucherUsage
{
    public Guid Id { get; set; }

    public Guid VoucherId { get; set; }
    public Voucher Voucher { get; set; } = null!;

    public Guid UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    public Guid SubOrderId { get; set; }
    public SubOrder SubOrder { get; set; } = null!;

    public decimal DiscountAmount { get; set; }
    public DateTime UsedAt { get; set; }
}
