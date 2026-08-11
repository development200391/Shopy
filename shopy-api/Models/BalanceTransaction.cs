namespace shopy_api.Models;

/// <summary>
/// Buku besar mutasi saldo toko — immutable (tidak ada edit/soft-delete), tiap baris adalah 1 kejadian.
/// </summary>
public class BalanceTransaction
{
    public Guid Id { get; set; }

    public Guid StoreId { get; set; }
    public Store Store { get; set; } = null!;

    public BalanceTransactionType Type { get; set; }

    // Signed: positif menambah saldo (mis. SaleIncome), negatif mengurangi (mis. Commission, Withdrawal).
    public decimal Amount { get; set; }
    public decimal BalanceAfter { get; set; }

    public Guid? SubOrderId { get; set; }
    public SubOrder? SubOrder { get; set; }

    public Guid? WithdrawalId { get; set; }
    public Withdrawal? Withdrawal { get; set; }

    public string? Description { get; set; }

    public DateTime CreatedAt { get; set; }
}
