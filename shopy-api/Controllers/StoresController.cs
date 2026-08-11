using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Catalog;
using shopy_api.Models.Stores;

namespace shopy_api.Controllers;

[ApiController]
[Route("api/stores")]
public class StoresController(ShopyDbContext dbContext) : ControllerBase
{
    private const int MaxPageSize = 100;

    // Toko yang belum Active sengaja tidak muncul di endpoint publik — pembeli tidak
    // perlu melihat toko yang belum diverifikasi (lihat TASKSELLER.md Fase 2).
    [HttpGet("{slug}")]
    public async Task<ActionResult<StorePublicProfileDto>> GetBySlug(string slug)
    {
        var store = await dbContext.Stores
            .SingleOrDefaultAsync(s => s.Slug == slug && s.Status == StoreStatus.Active);

        if (store is null)
        {
            return NotFound(new { message = "Toko tidak ditemukan." });
        }

        return Ok(new StorePublicProfileDto(
            store.Id, store.Name, store.Slug, store.Description, store.LogoUrl, store.BannerUrl,
            store.PhoneNumber, store.RatingAverage, store.RatingCount, store.ProductCount,
            store.FollowerCount, store.IsOpen));
    }

    [HttpGet("{slug}/products")]
    public async Task<ActionResult<PagedResult<ProductListItemDto>>> GetProducts(
        string slug, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var storeId = await dbContext.Stores
            .Where(s => s.Slug == slug && s.Status == StoreStatus.Active)
            .Select(s => (Guid?)s.Id)
            .SingleOrDefaultAsync();

        if (storeId is null)
        {
            return NotFound(new { message = "Toko tidak ditemukan." });
        }

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, MaxPageSize);

        var products = dbContext.Products.Where(p => p.IsActive && p.StoreId == storeId);
        var totalCount = await products.CountAsync();
        var items = await products
            .OrderByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new ProductListItemDto(
                p.Id, p.Name, p.Slug, p.Price, p.ImageUrl, p.RatingAverage, p.RatingCount,
                p.CategoryId, p.Category.Name, p.StoreId, p.Store.Name, p.Store.Slug))
            .ToListAsync();

        return Ok(new PagedResult<ProductListItemDto>(items, page, pageSize, totalCount));
    }
}
