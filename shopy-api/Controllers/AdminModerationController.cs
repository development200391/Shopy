using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Services;

namespace shopy_api.Controllers;

/// <summary>
/// Takedown produk/ulasan bermasalah (TASKSELLER.md Fase 9) — reuse soft-delete
/// (<c>ISoftDeletable</c>) yang sama seperti seller pakai buat hapus produknya sendiri
/// (<c>SellerProductsController</c>'s <c>DELETE</c>); global query filter di
/// <c>ShopyDbContext</c> otomatis nyembunyiin baris <c>IsDeleted=true</c> dari semua query.
/// </summary>
[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/admin")]
public class AdminModerationController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpPost("products/{id:guid}/takedown")]
    public async Task<IActionResult> TakedownProduct(Guid id)
    {
        var product = await dbContext.Products.SingleOrDefaultAsync(p => p.Id == id);
        if (product is null)
        {
            return NotFound(new { message = "Produk tidak ditemukan." });
        }

        product.IsDeleted = true;
        product.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("reviews/{id:guid}/takedown")]
    public async Task<IActionResult> TakedownReview(Guid id)
    {
        var review = await dbContext.Reviews.SingleOrDefaultAsync(r => r.Id == id);
        if (review is null)
        {
            return NotFound(new { message = "Ulasan tidak ditemukan." });
        }

        review.IsDeleted = true;
        await dbContext.SaveChangesAsync();

        await ReviewAggregationHelper.RecalculateProductRatingAsync(dbContext, review.ProductId);
        if (review.StoreId is not null)
        {
            await ReviewAggregationHelper.RecalculateStoreRatingAsync(dbContext, review.StoreId.Value);
        }
        await dbContext.SaveChangesAsync();

        return NoContent();
    }
}
