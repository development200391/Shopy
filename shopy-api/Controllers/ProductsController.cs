using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models.Catalog;

namespace shopy_api.Controllers;

[ApiController]
[Route("api/products")]
public class ProductsController(ShopyDbContext dbContext) : ControllerBase
{
    private const int MaxPageSize = 100;

    [HttpGet]
    public async Task<ActionResult<PagedResult<ProductListItemDto>>> GetProducts([FromQuery] ProductQuery query)
    {
        var page = Math.Max(query.Page, 1);
        var pageSize = Math.Clamp(query.PageSize, 1, MaxPageSize);

        var products = dbContext.Products.Where(p => p.IsActive).AsQueryable();

        if (!string.IsNullOrWhiteSpace(query.Q))
        {
            var term = $"%{query.Q.Trim()}%";
            products = products.Where(p => EF.Functions.ILike(p.Name, term) || EF.Functions.ILike(p.Description ?? "", term));
        }

        var categoryId = query.CategoryId;
        if (categoryId is null && !string.IsNullOrWhiteSpace(query.CategorySlug))
        {
            categoryId = await dbContext.Categories
                .Where(c => c.Slug == query.CategorySlug)
                .Select(c => (Guid?)c.Id)
                .SingleOrDefaultAsync();
        }

        if (categoryId is not null)
        {
            var categoryIds = await GetCategoryIdsIncludingDescendantsAsync(categoryId.Value);
            products = products.Where(p => categoryIds.Contains(p.CategoryId));
        }

        if (query.MinPrice is not null)
        {
            products = products.Where(p => p.Price >= query.MinPrice);
        }

        if (query.MaxPrice is not null)
        {
            products = products.Where(p => p.Price <= query.MaxPrice);
        }

        products = query.Sort switch
        {
            ProductSort.PriceAsc => products.OrderBy(p => p.Price),
            ProductSort.PriceDesc => products.OrderByDescending(p => p.Price),
            ProductSort.RatingDesc => products.OrderByDescending(p => p.RatingAverage).ThenByDescending(p => p.RatingCount),
            _ => products.OrderByDescending(p => p.CreatedAt),
        };

        var totalCount = await products.CountAsync();
        var items = await products
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new ProductListItemDto(
                p.Id, p.Name, p.Slug, p.Price, p.ImageUrl,
                p.RatingAverage, p.RatingCount, p.CategoryId, p.Category.Name))
            .ToListAsync();

        return Ok(new PagedResult<ProductListItemDto>(items, page, pageSize, totalCount));
    }

    [HttpGet("{slug}")]
    public async Task<ActionResult<ProductDetailDto>> GetBySlug(string slug)
    {
        var product = await dbContext.Products
            .Include(p => p.Category)
            .Where(p => p.IsActive)
            .SingleOrDefaultAsync(p => p.Slug == slug);

        if (product is null)
        {
            return NotFound(new { message = "Produk tidak ditemukan." });
        }

        var dto = new ProductDetailDto(
            product.Id, product.Name, product.Slug, product.Description, product.Price,
            product.Stock, product.ImageUrl, product.RatingAverage, product.RatingCount,
            product.CategoryId, product.Category.Name, product.CreatedAt);

        return Ok(dto);
    }

    private async Task<List<Guid>> GetCategoryIdsIncludingDescendantsAsync(Guid rootId)
    {
        var allCategories = await dbContext.Categories
            .Select(c => new { c.Id, c.ParentCategoryId })
            .ToListAsync();

        var result = new List<Guid> { rootId };
        var frontier = new List<Guid> { rootId };
        while (frontier.Count > 0)
        {
            var children = allCategories.Where(c => c.ParentCategoryId is not null && frontier.Contains(c.ParentCategoryId.Value))
                .Select(c => c.Id)
                .ToList();
            result.AddRange(children);
            frontier = children;
        }

        return result;
    }
}
