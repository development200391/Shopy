namespace shopy_api.Models;

public class SubOrder : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid OrderId { get; set; }
    public Order Order { get; set; } = null!;

    public Guid StoreId { get; set; }
    public Store Store { get; set; } = null!;

    public string SubOrderNumber { get; set; } = string.Empty;
    public SubOrderStatus Status { get; set; } = SubOrderStatus.WaitingPayment;

    public decimal Subtotal { get; set; }
    public decimal ShippingCost { get; set; }
    public decimal VoucherDiscount { get; set; }
    public decimal CommissionAmount { get; set; }
    public decimal SellerEarning { get; set; }

    public string? CourierCode { get; set; }
    public string? CourierService { get; set; }
    public string? TrackingNumber { get; set; }

    public DateTime? ShippedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? AutoCancelAt { get; set; }
    public string? CancelReason { get; set; }

    public ICollection<OrderItem> OrderItems { get; set; } = [];
    public ICollection<SubOrderStatusHistory> StatusHistories { get; set; } = [];

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
