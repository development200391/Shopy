namespace shopy_api.Models;

/// <summary>
/// Jejak setiap perubahan status sub-order, dipakai buat timeline lacak pesanan per toko.
/// </summary>
public class SubOrderStatusHistory
{
    public Guid Id { get; set; }

    public Guid SubOrderId { get; set; }
    public SubOrder SubOrder { get; set; } = null!;

    public SubOrderStatus Status { get; set; }
    public string? Note { get; set; }
    public Guid? ChangedByUserId { get; set; }

    public DateTime ChangedAt { get; set; }
}
