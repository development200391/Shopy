namespace shopy_api.Models.Sellers;

public record StoreBalanceDto(
    decimal AvailableBalance,
    decimal PendingBalance,
    decimal TotalEarning,
    decimal MonthlyEarning,
    decimal MonthlyCommission,
    int CompletedOrderCountThisMonth);

public record BalanceTransactionDto(
    Guid Id,
    string Type,
    decimal Amount,
    decimal BalanceAfter,
    string? Description,
    DateTime CreatedAt);

public record RequestWithdrawalRequest(Guid BankAccountId, decimal Amount);

public record WithdrawalDto(
    Guid Id,
    decimal Amount,
    decimal AdminFee,
    decimal NetAmount,
    string Status,
    string BankName,
    string AccountNumberMasked,
    DateTime RequestedAt,
    DateTime? ProcessedAt);
