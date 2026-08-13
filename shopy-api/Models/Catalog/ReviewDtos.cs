namespace shopy_api.Models.Catalog;

public record ReviewDto(
    Guid Id,
    string BuyerName,
    string? BuyerAvatarUrl,
    int Rating,
    string? Comment,
    IReadOnlyList<string> ImageUrls,
    string? SellerReply,
    DateTime? SellerRepliedAt,
    DateTime CreatedAt);

public record CreateReviewRequest(Guid ProductId, int Rating, string? Comment, IReadOnlyList<string>? ImageUrls);
