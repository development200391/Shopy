using shopy_api.Models;

namespace shopy_api.Models.Payments;

public record PaymentDto(
    Guid Id,
    Guid OrderId,
    string Method,
    string Status,
    string? VirtualAccountBank,
    string? VirtualAccountNumber,
    string? QrCodeUrl,
    DateTime? ExpiresAt,
    decimal Amount,
    DateTime CreatedAt);

public record CreatePaymentRequest(PaymentMethod Method);
