namespace shopy_api.Models;

public class Payment : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid OrderId { get; set; }
    public Order Order { get; set; } = null!;

    public PaymentMethod Method { get; set; }

    // Order ID yang dikirim ke Midtrans — bukan Order.OrderNumber langsung, karena
    // Midtrans butuh order_id unik per percobaan charge (kalau VA sebelumnya expired
    // & user coba bayar lagi, dibuat Payment baru dengan suffix "-P{n}").
    public string MidtransOrderId { get; set; } = string.Empty;
    public string? MidtransTransactionId { get; set; }

    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public decimal Amount { get; set; }

    public string? VirtualAccountBank { get; set; }
    public string? VirtualAccountNumber { get; set; }
    public string? QrCodeUrl { get; set; }
    public DateTime? ExpiresAt { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
