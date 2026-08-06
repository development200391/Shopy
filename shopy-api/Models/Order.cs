namespace shopy_api.Models;

public class Order : ISoftDeletable
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = string.Empty;

    public Guid UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    public Guid AddressId { get; set; }
    public Address Address { get; set; } = null!;

    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public decimal TotalAmount { get; set; }

    // Snapshot alamat pengiriman saat checkout, supaya histori order tidak berubah
    // walau data di Addresses berubah/dihapus belakangan.
    public string RecipientName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string FullAddress { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Province { get; set; } = string.Empty;
    public string PostalCode { get; set; } = string.Empty;

    public ICollection<OrderItem> OrderItems { get; set; } = [];

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
