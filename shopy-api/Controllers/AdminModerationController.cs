using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models.Admin;
using shopy_api.Models.Catalog;
using shopy_api.Services;

namespace shopy_api.Controllers;

/// <summary>
/// Takedown produk/ulasan bermasalah (TASKSELLER.md Fase 9) — reuse soft-delete
/// (<c>ISoftDeletable</c>) yang sama seperti seller pakai buat hapus produknya sendiri
/// (<c>SellerProductsController</c>'s <c>DELETE</c>); global query filter di
/// <c>ShopyDbContext</c> otomatis nyembunyiin baris <c>IsDeleted=true</c> dari semua query.
/// <c>GET</c> di bawah (TASKADMIN.md Fase 4) sengaja TIDAK pakai <c>IgnoreQueryFilters()</c> —
/// item yang sudah di-takedown otomatis hilang dari hasil pencarian (sama seperti query lain),
/// karena tidak ada aksi "restore" di scope ini, jadi menampilkannya lagi cuma bikin ramai.
/// </summary>
[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/admin")]
public class AdminModerationController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpGet("products")]
    public async Task<ActionResult<PagedResult<AdminProductListItemDto>>> GetProducts(
        [FromQuery] string? search, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = dbContext.Products.Include(p => p.Store).AsQueryable();
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = $"%{search.Trim()}%";
            query = query.Where(p => EF.Functions.ILike(p.Name, term) || EF.Functions.ILike(p.Store.Name, term));
        }
        query = query.OrderByDescending(p => p.CreatedAt);

        var totalCount = await query.CountAsync();
        var products = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

        return Ok(new PagedResult<AdminProductListItemDto>(products.Select(ToDto).ToList(), page, pageSize, totalCount));
    }

    [HttpGet("reviews")]
    public async Task<ActionResult<PagedResult<AdminReviewListItemDto>>> GetReviews(
        [FromQuery] string? search, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = dbContext.Reviews.Include(r => r.Product).Include(r => r.Store).Include(r => r.User).AsQueryable();
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = $"%{search.Trim()}%";
            query = query.Where(r => EF.Functions.ILike(r.Product.Name, term) || EF.Functions.ILike(r.User.FullName, term));
        }
        // Default: rating rendah dulu (paling butuh perhatian admin), baru terbaru di dalamnya.
        query = query.OrderBy(r => r.Rating).ThenByDescending(r => r.CreatedAt);

        var totalCount = await query.CountAsync();
        var reviews = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

        return Ok(new PagedResult<AdminReviewListItemDto>(reviews.Select(ToDto).ToList(), page, pageSize, totalCount));
    }

    private static AdminProductListItemDto ToDto(Models.Product p) => new(
        p.Id, p.Name, p.ImageUrl, p.Price, p.Stock, p.IsActive,
        p.StoreId, p.Store.Name, p.RatingAverage, p.RatingCount, p.CreatedAt);

    private static AdminReviewListItemDto ToDto(Models.Review r) => new(
        r.Id, r.ProductId, r.Product.Name, r.StoreId, r.Store?.Name,
        r.User.FullName, r.Rating, r.Comment, r.CreatedAt);

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
