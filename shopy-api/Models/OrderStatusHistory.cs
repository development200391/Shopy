namespace shopy_api.Models;

/// <summary>
/// Jejak setiap perubahan status pesanan, dipakai buat timeline lacak pesanan.
/// Baris pertama (Status = Pending) dibuat otomatis saat checkout.
/// </summary>
public class OrderStatusHistory
{
    public Guid Id { get; set; }

    public Guid OrderId { get; set; }
    public Order Order { get; set; } = null!;

    public OrderStatus Status { get; set; }
    public DateTime ChangedAt { get; set; }
}
