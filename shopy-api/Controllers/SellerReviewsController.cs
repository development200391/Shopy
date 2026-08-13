using System.Text.Json;
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
[Route("api/seller/reviews")]
public class SellerReviewsController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpGet("summary")]
    public async Task<ActionResult<SellerReviewSummaryDto>> GetSummary()
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var reviews = await dbContext.Reviews.Where(r => r.StoreId == storeId).ToListAsync();
        var total = reviews.Count;
        var average = total == 0 ? 0 : Math.Round((decimal)reviews.Average(r => r.Rating), 2);
        var unreplied = reviews.Count(r => r.SellerReply == null);

        var distribution = new List<RatingDistributionItemDto>();
        for (var stars = 5; stars >= 1; stars--)
        {
            var count = reviews.Count(r => r.Rating == stars);
            var percent = total == 0 ? 0 : (int)Math.Round(count * 100m / total);
            distribution.Add(new RatingDistributionItemDto(stars, count, percent));
        }

        return Ok(new SellerReviewSummaryDto(average, total, unreplied, distribution));
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<SellerReviewListItemDto>>> GetReviews(
        [FromQuery] string? filter, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = dbContext.Reviews.Where(r => r.StoreId == storeId);
        if (filter == "belum-dibalas")
        {
            query = query.Where(r => r.SellerReply == null);
        }
        else if (int.TryParse(filter, out var stars) && stars is >= 1 and <= 5)
        {
            query = query.Where(r => r.Rating == stars);
        }
        query = query.OrderByDescending(r => r.CreatedAt);

        var totalCount = await query.CountAsync();
        var reviews = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Include(r => r.User)
            .Include(r => r.Product)
            .ToListAsync();

        return Ok(new PagedResult<SellerReviewListItemDto>(reviews.Select(ToListItemDto).ToList(), page, pageSize, totalCount));
    }

    [HttpPost("{id:guid}/reply")]
    public async Task<ActionResult<SellerReviewListItemDto>> Reply(Guid id, ReplyReviewRequest request)
    {
        var storeId = await GetMyStoreIdAsync();
        var review = await dbContext.Reviews
            .Include(r => r.User)
            .Include(r => r.Product)
            .SingleOrDefaultAsync(r => r.Id == id && r.StoreId == storeId);
        if (review is null)
        {
            return NotFound(new { message = "Ulasan tidak ditemukan." });
        }

        if (string.IsNullOrWhiteSpace(request.Reply))
        {
            return BadRequest(new { message = "Balasan tidak boleh kosong." });
        }

        review.SellerReply = request.Reply.Trim();
        review.SellerRepliedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();

        return Ok(ToListItemDto(review));
    }

    private async Task<Guid?> GetMyStoreIdAsync()
    {
        var userId = User.GetUserId();
        return await dbContext.Stores
            .Where(s => s.OwnerUserId == userId)
            .Select(s => (Guid?)s.Id)
            .SingleOrDefaultAsync();
    }

    private static SellerReviewListItemDto ToListItemDto(Review r) => new(
        r.Id, r.User.FullName, r.User.AvatarUrl, r.ProductId, r.Product.Name, r.Rating, r.Comment,
        DeserializeImages(r.ImageUrls), r.SellerReply, r.SellerRepliedAt, r.CreatedAt);

    private static IReadOnlyList<string> DeserializeImages(string? json)
    {
        if (string.IsNullOrEmpty(json))
        {
            return [];
        }
        try
        {
            return JsonSerializer.Deserialize<List<string>>(json) ?? [];
        }
        catch (JsonException)
        {
            return [];
        }
    }
}
