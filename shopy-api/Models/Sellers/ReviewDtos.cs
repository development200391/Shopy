namespace shopy_api.Models.Sellers;

public record RatingDistributionItemDto(int Stars, int Count, int Percent);

public record SellerReviewSummaryDto(
    decimal Average,
    int TotalCount,
    int UnrepliedCount,
    IReadOnlyList<RatingDistributionItemDto> Distribution);

public record SellerReviewListItemDto(
    Guid Id,
    string BuyerName,
    string? BuyerAvatarUrl,
    Guid ProductId,
    string ProductName,
    int Rating,
    string? Comment,
    IReadOnlyList<string> ImageUrls,
    string? SellerReply,
    DateTime? SellerRepliedAt,
    DateTime CreatedAt);

public record ReplyReviewRequest(string Reply);
