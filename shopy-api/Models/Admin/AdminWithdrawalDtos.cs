namespace shopy_api.Models.Admin;

public record AdminWithdrawalListItemDto(
    Guid Id,
    string StoreName,
    decimal Amount,
    decimal AdminFee,
    decimal NetAmount,
    string Status,
    string BankName,
    string AccountNumberMasked,
    DateTime RequestedAt,
    DateTime? ProcessedAt);

public record UpdateWithdrawalStatusRequest(string Status, string? Reason);
