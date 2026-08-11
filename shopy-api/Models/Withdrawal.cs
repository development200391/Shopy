namespace shopy_api.Models;

public class Withdrawal : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid StoreId { get; set; }
    public Store Store { get; set; } = null!;

    public Guid BankAccountId { get; set; }
    public BankAccount BankAccount { get; set; } = null!;

    public decimal Amount { get; set; }
    public decimal AdminFee { get; set; }
    public decimal NetAmount { get; set; }

    public WithdrawalStatus Status { get; set; } = WithdrawalStatus.Pending;
    public string? RejectReason { get; set; }

    public DateTime RequestedAt { get; set; }
    public DateTime? ProcessedAt { get; set; }

    public bool IsDeleted { get; set; }
}
