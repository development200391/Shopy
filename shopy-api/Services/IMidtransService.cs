using shopy_api.Models;

namespace shopy_api.Services;

public record MidtransChargeResult(
    string TransactionId,
    string TransactionStatus,
    string? VaBank,
    string? VaNumber,
    string? QrCodeUrl,
    DateTime? ExpiryTime);

public record MidtransStatusResult(string TransactionStatus, string? FraudStatus);

public interface IMidtransService
{
    bool IsConfigured { get; }

    Task<MidtransChargeResult> ChargeAsync(string midtransOrderId, decimal grossAmount, PaymentMethod method);

    Task<MidtransStatusResult> GetStatusAsync(string midtransOrderId);

    bool VerifySignature(string orderId, string statusCode, string grossAmount, string signatureKey);
}
