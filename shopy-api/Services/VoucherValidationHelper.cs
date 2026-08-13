using shopy_api.Models;

namespace shopy_api.Services;

/// <summary>
/// Logika validasi &amp; penghitungan diskon voucher — dipakai identik oleh endpoint validasi
/// buyer-facing (<c>POST /api/vouchers/validate</c>) dan checkout (<c>OrdersController.Checkout</c>),
/// supaya checkout tidak pernah percaya angka diskon dari client (TASKSELLER.md Fase 6).
/// </summary>
public static class VoucherValidationHelper
{
    public record Result(bool Valid, string? Message, decimal DiscountAmount);

    public static Result Validate(Voucher? voucher, decimal subtotal, decimal shippingCost, DateTime now)
    {
        if (voucher is null)
        {
            return new Result(false, "Kode voucher tidak ditemukan.", 0);
        }
        if (!voucher.IsActive)
        {
            return new Result(false, "Voucher sedang tidak aktif.", 0);
        }
        if (now < voucher.StartAt || now > voucher.EndAt)
        {
            return new Result(false, "Voucher belum berlaku atau sudah berakhir.", 0);
        }
        if (voucher.Quota is not null && voucher.UsedCount >= voucher.Quota)
        {
            return new Result(false, "Kuota voucher sudah habis.", 0);
        }
        if (voucher.MinPurchase is not null && subtotal < voucher.MinPurchase)
        {
            return new Result(false, $"Minimal belanja Rp{voucher.MinPurchase:N0} untuk pakai voucher ini.", 0);
        }

        var discount = voucher.Type switch
        {
            VoucherType.Percentage => Math.Round(subtotal * voucher.Value / 100m, 2),
            VoucherType.FixedAmount => voucher.Value,
            VoucherType.FreeShipping => Math.Min(voucher.Value, shippingCost),
            _ => 0m,
        };

        if (voucher.Type != VoucherType.FreeShipping && voucher.MaxDiscount is not null)
        {
            discount = Math.Min(discount, voucher.MaxDiscount.Value);
        }
        discount = Math.Min(discount, subtotal + shippingCost);

        return new Result(true, null, discount);
    }
}
