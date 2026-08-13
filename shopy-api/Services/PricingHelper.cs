using shopy_api.Models;

namespace shopy_api.Services;

/// <summary>
/// Harga efektif produk — dipakai konsisten di katalog publik, keranjang, dan checkout
/// (TASKSELLER.md Fase 6) supaya diskon (`Product.DiscountPrice`) otomatis berlaku di mana pun
/// harga produk dipakai, tanpa logika tanggal/kondisi diskon terduplikasi di tiap controller.
/// </summary>
public static class PricingHelper
{
    public static bool IsDiscounted(Product product, DateTime? now = null)
    {
        var at = now ?? DateTime.UtcNow;
        return product.DiscountPrice is not null
            && product.DiscountStartAt is not null && product.DiscountStartAt <= at
            && product.DiscountEndAt is not null && product.DiscountEndAt >= at;
    }

    public static decimal EffectivePrice(Product product, DateTime? now = null)
    {
        return IsDiscounted(product, now) ? product.DiscountPrice!.Value : product.Price;
    }
}
