using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Wishlists;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize]
[Route("api/wishlist")]
public class WishlistController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<WishlistItemDto>>> GetWishlist()
    {
        var userId = User.GetUserId();
        var items = await dbContext.WishlistItems
            .Where(w => w.UserId == userId)
            .Include(w => w.Product)
            .OrderByDescending(w => w.CreatedAt)
            .Select(w => new WishlistItemDto(
                w.Id, w.ProductId, w.Product.Name, w.Product.Slug, w.Product.ImageUrl,
                w.Product.Price, w.Product.RatingAverage))
            .ToListAsync();

        return Ok(items);
    }

    [HttpPost]
    public async Task<ActionResult<WishlistItemDto>> AddFavorite(AddWishlistItemRequest request)
    {
        var userId = User.GetUserId();

        var product = await dbContext.Products.SingleOrDefaultAsync(p => p.Id == request.ProductId && p.IsActive);
        if (product is null)
        {
            return NotFound(new { message = "Produk tidak ditemukan." });
        }

        var existing = await dbContext.WishlistItems
            .SingleOrDefaultAsync(w => w.UserId == userId && w.ProductId == request.ProductId);
        if (existing is not null)
        {
            return Ok(new WishlistItemDto(
                existing.Id, product.Id, product.Name, product.Slug, product.ImageUrl,
                product.Price, product.RatingAverage));
        }

        var item = new WishlistItem
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ProductId = product.Id,
            CreatedAt = DateTime.UtcNow,
        };
        dbContext.WishlistItems.Add(item);
        await dbContext.SaveChangesAsync();

        return Ok(new WishlistItemDto(
            item.Id, product.Id, product.Name, product.Slug, product.ImageUrl,
            product.Price, product.RatingAverage));
    }

    [HttpDelete("{productId:guid}")]
    public async Task<IActionResult> RemoveFavorite(Guid productId)
    {
        var userId = User.GetUserId();
        var item = await dbContext.WishlistItems
            .SingleOrDefaultAsync(w => w.UserId == userId && w.ProductId == productId);
        if (item is null)
        {
            return NotFound(new { message = "Produk tidak ada di wishlist." });
        }

        item.IsDeleted = true;
        await dbContext.SaveChangesAsync();

        return NoContent();
    }
}
