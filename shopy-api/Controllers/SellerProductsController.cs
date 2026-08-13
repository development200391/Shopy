using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Catalog;
using shopy_api.Models.Sellers;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize(Roles = "Seller")]
[Route("api/seller/products")]
public partial class SellerProductsController(ShopyDbContext dbContext) : ControllerBase
{
    private const int MaxPageSize = 100;

    [HttpGet]
    public async Task<ActionResult<PagedResult<SellerProductListItemDto>>> GetProducts(
        [FromQuery] string status = "all",
        [FromQuery] string? q = null,
        [FromQuery] string sort = "newest",
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, MaxPageSize);

        var products = dbContext.Products.Where(p => p.StoreId == storeId);

        products = status switch
        {
            "active" => products.Where(p => p.IsActive && p.Stock > 0),
            "inactive" => products.Where(p => !p.IsActive),
            "outofstock" => products.Where(p => p.IsActive && p.Stock == 0),
            _ => products,
        };

        if (!string.IsNullOrWhiteSpace(q))
        {
            var term = $"%{q.Trim()}%";
            products = products.Where(p => EF.Functions.ILike(p.Name, term));
        }

        products = sort switch
        {
            "priceAsc" => products.OrderBy(p => p.Price),
            "priceDesc" => products.OrderByDescending(p => p.Price),
            "stockAsc" => products.OrderBy(p => p.Stock),
            _ => products.OrderByDescending(p => p.CreatedAt),
        };

        var totalCount = await products.CountAsync();
        var items = await products
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new SellerProductListItemDto(
                p.Id, p.Name, p.Slug, p.Price, p.ImageUrl, p.Stock, p.IsActive, p.SoldCount))
            .ToListAsync();

        return Ok(new PagedResult<SellerProductListItemDto>(items, page, pageSize, totalCount));
    }

    [HttpGet("low-stock")]
    public async Task<ActionResult<IReadOnlyList<LowStockProductDto>>> GetLowStock([FromQuery] int threshold = 10)
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var items = await dbContext.Products
            .Where(p => p.StoreId == storeId && p.IsActive && p.Stock <= threshold)
            .OrderBy(p => p.Stock)
            .Select(p => new LowStockProductDto(p.Id, p.Name, p.Stock, p.ImageUrl))
            .ToListAsync();

        return Ok(items);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<SellerProductDetailDto>> GetProduct(Guid id)
    {
        var storeId = await GetMyStoreIdAsync();
        var product = await dbContext.Products
            .Include(p => p.Category)
            .Include(p => p.Images.OrderBy(i => i.SortOrder))
            .SingleOrDefaultAsync(p => p.Id == id && p.StoreId == storeId);

        if (product is null)
        {
            return NotFound(new { message = "Produk tidak ditemukan." });
        }

        return Ok(ToDetailDto(product));
    }

    [HttpPost]
    public async Task<ActionResult<SellerProductDetailDto>> CreateProduct(SaveProductRequest request)
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        if (!Enum.TryParse<ProductCondition>(request.Condition, out var condition))
        {
            return BadRequest(new { message = "Kondisi produk tidak dikenal." });
        }

        var slug = await GenerateUniqueSlugAsync(request.Name);

        var product = new Product
        {
            Id = Guid.NewGuid(),
            StoreId = storeId.Value,
            CategoryId = request.CategoryId,
            Name = request.Name,
            Slug = slug,
            Description = request.Description,
            Price = request.Price,
            Stock = request.Stock,
            Weight = request.Weight,
            Condition = condition,
            IsActive = request.IsActive,
            ImageUrl = request.ImageUrls.FirstOrDefault(),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
        };
        dbContext.Products.Add(product);

        AddImages(product.Id, request.ImageUrls);

        var store = await dbContext.Stores.SingleAsync(s => s.Id == storeId);
        store.ProductCount++;

        await dbContext.SaveChangesAsync();

        return await GetProduct(product.Id);
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<SellerProductDetailDto>> UpdateProduct(Guid id, SaveProductRequest request)
    {
        var storeId = await GetMyStoreIdAsync();
        var product = await dbContext.Products.SingleOrDefaultAsync(p => p.Id == id && p.StoreId == storeId);
        if (product is null)
        {
            return NotFound(new { message = "Produk tidak ditemukan." });
        }

        if (!Enum.TryParse<ProductCondition>(request.Condition, out var condition))
        {
            return BadRequest(new { message = "Kondisi produk tidak dikenal." });
        }

        // Slug sengaja tidak diubah walau nama berubah — supaya link yang sudah beredar di app pembeli tetap valid.
        product.CategoryId = request.CategoryId;
        product.Name = request.Name;
        product.Description = request.Description;
        product.Price = request.Price;
        product.Stock = request.Stock;
        product.Weight = request.Weight;
        product.Condition = condition;
        product.IsActive = request.IsActive;
        product.ImageUrl = request.ImageUrls.FirstOrDefault();
        product.UpdatedAt = DateTime.UtcNow;

        var existingImages = await dbContext.ProductImages.Where(i => i.ProductId == product.Id).ToListAsync();
        dbContext.ProductImages.RemoveRange(existingImages);
        AddImages(product.Id, request.ImageUrls);

        await dbContext.SaveChangesAsync();

        return await GetProduct(product.Id);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteProduct(Guid id)
    {
        var storeId = await GetMyStoreIdAsync();
        var product = await dbContext.Products.SingleOrDefaultAsync(p => p.Id == id && p.StoreId == storeId);
        if (product is null)
        {
            return NotFound(new { message = "Produk tidak ditemukan." });
        }

        product.IsDeleted = true;

        var store = await dbContext.Stores.SingleAsync(s => s.Id == storeId);
        store.ProductCount = Math.Max(0, store.ProductCount - 1);

        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    [HttpPatch("{id:guid}/active")]
    public async Task<ActionResult<SellerProductDetailDto>> SetActive(Guid id, SetProductActiveRequest request)
    {
        var storeId = await GetMyStoreIdAsync();
        var product = await dbContext.Products.SingleOrDefaultAsync(p => p.Id == id && p.StoreId == storeId);
        if (product is null)
        {
            return NotFound(new { message = "Produk tidak ditemukan." });
        }

        product.IsActive = request.IsActive;
        product.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();

        return await GetProduct(product.Id);
    }

    [HttpPatch("bulk")]
    public async Task<IActionResult> BulkUpdate(BulkUpdateProductsRequest request)
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var ids = request.Items.Select(i => i.Id).ToList();
        var products = await dbContext.Products
            .Where(p => p.StoreId == storeId && ids.Contains(p.Id))
            .ToDictionaryAsync(p => p.Id);

        foreach (var item in request.Items)
        {
            if (!products.TryGetValue(item.Id, out var product))
            {
                continue;
            }

            product.Price = item.Price;
            product.Stock = item.Stock;
            product.UpdatedAt = DateTime.UtcNow;
        }

        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    private void AddImages(Guid productId, IReadOnlyList<string> urls)
    {
        for (var i = 0; i < urls.Count; i++)
        {
            dbContext.ProductImages.Add(new ProductImage
            {
                Id = Guid.NewGuid(),
                ProductId = productId,
                Url = urls[i],
                SortOrder = i,
                IsPrimary = i == 0,
            });
        }
    }

    private async Task<Guid?> GetMyStoreIdAsync()
    {
        var userId = User.GetUserId();
        return await dbContext.Stores
            .Where(s => s.OwnerUserId == userId)
            .Select(s => (Guid?)s.Id)
            .SingleOrDefaultAsync();
    }

    private async Task<string> GenerateUniqueSlugAsync(string name)
    {
        var baseSlug = Slugify(name);
        var slug = baseSlug;
        var suffix = 2;
        while (await dbContext.Products.AnyAsync(p => p.Slug == slug))
        {
            slug = $"{baseSlug}-{suffix}";
            suffix++;
        }
        return slug;
    }

    private static string Slugify(string input)
    {
        var lower = input.Trim().ToLowerInvariant();
        var withDashes = NonAlphanumericRegex().Replace(lower, "-");
        return withDashes.Trim('-');
    }

    private static SellerProductDetailDto ToDetailDto(Product product) => new(
        product.Id, product.Name, product.Slug, product.Description, product.Price, product.Stock,
        product.Weight, product.Condition.ToString(), product.CategoryId, product.Category.Name, product.IsActive,
        product.Images.Select(i => new ProductImageDto(i.Id, i.Url, i.SortOrder, i.IsPrimary)).ToList());

    [GeneratedRegex("[^a-z0-9]+")]
    private static partial Regex NonAlphanumericRegex();
}
