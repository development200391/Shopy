using System.Globalization;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using shopy_api.Models;

namespace shopy_api.Services;

/// <summary>
/// Integrasi Midtrans Core API (bukan Snap) supaya UI pembayaran bisa custom
/// sesuai mockup Bold & Colorful, bukan halaman/webview bawaan Midtrans.
/// Dokumentasi: https://docs.midtrans.com/reference/core-api-overview
/// </summary>
public class MidtransService(IHttpClientFactory httpClientFactory, IConfiguration configuration) : IMidtransService
{
    private string? ServerKey => configuration["Midtrans:ServerKey"];

    private bool IsProduction => configuration.GetValue("Midtrans:IsProduction", false);

    private string BaseUrl => IsProduction ? "https://api.midtrans.com" : "https://api.sandbox.midtrans.com";

    public bool IsConfigured => !string.IsNullOrEmpty(ServerKey);

    public async Task<MidtransChargeResult> ChargeAsync(string midtransOrderId, decimal grossAmount, PaymentMethod method)
    {
        var client = CreateClient();

        var payload = new Dictionary<string, object>
        {
            ["payment_type"] = MethodToPaymentType(method),
            ["transaction_details"] = new Dictionary<string, object>
            {
                ["order_id"] = midtransOrderId,
                ["gross_amount"] = (long)grossAmount,
            },
        };

        switch (method)
        {
            case PaymentMethod.BcaVa:
                payload["bank_transfer"] = new Dictionary<string, object> { ["bank"] = "bca" };
                payload["custom_expiry"] = new Dictionary<string, object> { ["expiry_duration"] = 24, ["unit"] = "hour" };
                break;
            case PaymentMethod.BniVa:
                payload["bank_transfer"] = new Dictionary<string, object> { ["bank"] = "bni" };
                payload["custom_expiry"] = new Dictionary<string, object> { ["expiry_duration"] = 24, ["unit"] = "hour" };
                break;
            case PaymentMethod.GoPay:
                payload["gopay"] = new Dictionary<string, object> { ["enable_callback"] = false };
                break;
            case PaymentMethod.Qris:
                payload["qris"] = new Dictionary<string, object> { ["acquirer"] = "gopay" };
                break;
        }

        using var response = await client.PostAsJsonAsync($"{BaseUrl}/v2/charge", payload);
        var body = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;

        if (!response.IsSuccessStatusCode)
        {
            var message = root.TryGetProperty("status_message", out var msg) ? msg.GetString() : "Gagal membuat transaksi pembayaran.";
            throw new InvalidOperationException(message ?? "Gagal membuat transaksi pembayaran.");
        }

        var transactionId = root.GetProperty("transaction_id").GetString()!;
        var transactionStatus = root.GetProperty("transaction_status").GetString()!;

        string? vaBank = null;
        string? vaNumber = null;
        if (root.TryGetProperty("va_numbers", out var vaNumbers) && vaNumbers.GetArrayLength() > 0)
        {
            var first = vaNumbers[0];
            vaBank = first.GetProperty("bank").GetString();
            vaNumber = first.GetProperty("va_number").GetString();
        }

        string? qrCodeUrl = null;
        if (root.TryGetProperty("actions", out var actions))
        {
            foreach (var action in actions.EnumerateArray())
            {
                if (action.GetProperty("name").GetString() == "generate-qr-code")
                {
                    qrCodeUrl = action.GetProperty("url").GetString();
                    break;
                }
            }
        }

        DateTime? expiryTime = null;
        if (root.TryGetProperty("expiry_time", out var expiry) && expiry.GetString() is { } expiryString)
        {
            // Format Midtrans: "yyyy-MM-dd HH:mm:ss" dalam WIB (UTC+7).
            if (DateTime.TryParse(expiryString, CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsed))
            {
                expiryTime = DateTime.SpecifyKind(parsed, DateTimeKind.Unspecified).AddHours(-7).ToUniversalTime();
            }
        }

        return new MidtransChargeResult(transactionId, transactionStatus, vaBank, vaNumber, qrCodeUrl, expiryTime);
    }

    public async Task<MidtransStatusResult> GetStatusAsync(string midtransOrderId)
    {
        var client = CreateClient();
        using var response = await client.GetAsync($"{BaseUrl}/v2/{Uri.EscapeDataString(midtransOrderId)}/status");
        var body = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;

        if (!response.IsSuccessStatusCode)
        {
            var message = root.TryGetProperty("status_message", out var msg) ? msg.GetString() : "Gagal mengecek status pembayaran.";
            throw new InvalidOperationException(message ?? "Gagal mengecek status pembayaran.");
        }

        var status = root.GetProperty("transaction_status").GetString()!;
        var fraud = root.TryGetProperty("fraud_status", out var f) ? f.GetString() : null;
        return new MidtransStatusResult(status, fraud);
    }

    public bool VerifySignature(string orderId, string statusCode, string grossAmount, string signatureKey)
    {
        if (string.IsNullOrEmpty(ServerKey))
        {
            return false;
        }

        var raw = $"{orderId}{statusCode}{grossAmount}{ServerKey}";
        var hash = SHA512.HashData(Encoding.UTF8.GetBytes(raw));
        var computed = Convert.ToHexStringLower(hash);
        return string.Equals(computed, signatureKey, StringComparison.OrdinalIgnoreCase);
    }

    private HttpClient CreateClient()
    {
        if (string.IsNullOrEmpty(ServerKey))
        {
            throw new InvalidOperationException("Midtrans:ServerKey belum dikonfigurasi.");
        }

        var client = httpClientFactory.CreateClient();
        var basicAuth = Convert.ToBase64String(Encoding.ASCII.GetBytes($"{ServerKey}:"));
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", basicAuth);
        client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        return client;
    }

    private static string MethodToPaymentType(PaymentMethod method) => method switch
    {
        PaymentMethod.BcaVa or PaymentMethod.BniVa => "bank_transfer",
        PaymentMethod.GoPay => "gopay",
        PaymentMethod.Qris => "qris",
        _ => throw new ArgumentOutOfRangeException(nameof(method)),
    };
}
