namespace shopy_api.Models;

public class BankAccount : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid StoreId { get; set; }
    public Store Store { get; set; } = null!;

    public string BankCode { get; set; } = string.Empty;
    public string BankName { get; set; } = string.Empty;
    public string AccountNumber { get; set; } = string.Empty;
    public string AccountHolderName { get; set; } = string.Empty;
    public bool IsVerified { get; set; }
    public bool IsDefault { get; set; }

    public bool IsDeleted { get; set; }
}
