using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Catalog;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Route("api")]
public class ReviewsController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpGet("products/{id:guid}/reviews")]
    public async Task<ActionResult<PagedResult<ReviewDto>>> GetProductReviews(
        Guid id, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = dbContext.Reviews.Where(r => r.ProductId == id).OrderByDescending(r => r.CreatedAt);
        var totalCount = await query.CountAsync();
        var reviews = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Include(r => r.User)
            .ToListAsync();

        return Ok(new PagedResult<ReviewDto>(reviews.Select(ToDto).ToList(), page, pageSize, totalCount));
    }

    [Authorize]
    [HttpPost("orders/{subOrderId:guid}/reviews")]
    public async Task<ActionResult<ReviewDto>> CreateReview(Guid subOrderId, CreateReviewRequest request)
    {
        var userId = User.GetUserId();

        var subOrder = await dbContext.SubOrders
            .Include(so => so.Order)
            .Include(so => so.OrderItems)
            .SingleOrDefaultAsync(so => so.Id == subOrderId && so.Order.UserId == userId);
        if (subOrder is null)
        {
            return NotFound(new { message = "Pesanan tidak ditemukan." });
        }
        if (subOrder.Status != SubOrderStatus.Completed)
        {
            return BadRequest(new { message = "Pesanan belum selesai — belum bisa diberi ulasan." });
        }
        if (!subOrder.OrderItems.Any(oi => oi.ProductId == request.ProductId))
        {
            return BadRequest(new { message = "Produk ini tidak ada di pesanan tersebut." });
        }
        if (request.Rating is < 1 or > 5)
        {
            return BadRequest(new { message = "Rating harus antara 1-5." });
        }
        if (await dbContext.Reviews.AnyAsync(r => r.ProductId == request.ProductId && r.UserId == userId))
        {
            return Conflict(new { message = "Kamu sudah memberi ulasan untuk produk ini." });
        }

        var review = new Review
        {
            Id = Guid.NewGuid(),
            ProductId = request.ProductId,
            UserId = userId,
            StoreId = subOrder.StoreId,
            SubOrderId = subOrder.Id,
            Rating = request.Rating,
            Comment = string.IsNullOrWhiteSpace(request.Comment) ? null : request.Comment,
            ImageUrls = request.ImageUrls is null || request.ImageUrls.Count == 0
                ? null
                : JsonSerializer.Serialize(request.ImageUrls),
            CreatedAt = DateTime.UtcNow,
        };
        dbContext.Reviews.Add(review);
        await dbContext.SaveChangesAsync();

        await ReviewAggregationHelper.RecalculateProductRatingAsync(dbContext, request.ProductId);
        await ReviewAggregationHelper.RecalculateStoreRatingAsync(dbContext, subOrder.StoreId);
        await dbContext.SaveChangesAsync();

        var user = await dbContext.Users.SingleAsync(u => u.Id == userId);
        return Ok(ToDto(review, user));
    }

    private static ReviewDto ToDto(Review r) => ToDto(r, r.User);

    private static ReviewDto ToDto(Review r, ApplicationUser user) => new(
        r.Id, user.FullName, user.AvatarUrl, r.Rating, r.Comment,
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
