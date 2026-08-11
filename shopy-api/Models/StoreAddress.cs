namespace shopy_api.Models;

public class StoreAddress : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid StoreId { get; set; }
    public Store Store { get; set; } = null!;

    public string Label { get; set; } = string.Empty;
    public string PicName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string FullAddress { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string Province { get; set; } = string.Empty;
    public string PostalCode { get; set; } = string.Empty;
    public bool IsDefault { get; set; }

    public bool IsDeleted { get; set; }
}
