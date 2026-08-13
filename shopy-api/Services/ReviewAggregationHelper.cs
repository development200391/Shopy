using Microsoft.EntityFrameworkCore;
using shopy_api.Data;

namespace shopy_api.Services;

/// <summary>
/// Hitung ulang rating agregat produk &amp; toko setelah ada ulasan baru (TASKSELLER.md Fase 7).
/// Dipisah dari controller supaya konsisten kalau nanti dipanggil dari tempat lain juga
/// (mis. moderasi ulasan).
/// </summary>
public static class ReviewAggregationHelper
{
    public static async Task RecalculateProductRatingAsync(ShopyDbContext dbContext, Guid productId)
    {
        var product = await dbContext.Products.SingleAsync(p => p.Id == productId);
        var reviews = await dbContext.Reviews.Where(r => r.ProductId == productId).ToListAsync();

        product.RatingCount = reviews.Count;
        product.RatingAverage = reviews.Count == 0 ? 0 : Math.Round((decimal)reviews.Average(r => r.Rating), 2);
    }

    public static async Task RecalculateStoreRatingAsync(ShopyDbContext dbContext, Guid storeId)
    {
        var store = await dbContext.Stores.SingleAsync(s => s.Id == storeId);
        var reviews = await dbContext.Reviews.Where(r => r.StoreId == storeId).ToListAsync();

        store.RatingCount = reviews.Count;
        store.RatingAverage = reviews.Count == 0 ? 0 : Math.Round((decimal)reviews.Average(r => r.Rating), 2);
    }
}
