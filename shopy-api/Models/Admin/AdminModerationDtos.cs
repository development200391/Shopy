namespace shopy_api.Models.Admin;

public record AdminProductListItemDto(
    Guid Id,
    string Name,
    string? ImageUrl,
    decimal Price,
    int Stock,
    bool IsActive,
    Guid StoreId,
    string StoreName,
    decimal RatingAverage,
    int RatingCount,
    DateTime CreatedAt);

public record AdminReviewListItemDto(
    Guid Id,
    Guid ProductId,
    string ProductName,
    Guid? StoreId,
    string? StoreName,
    string BuyerName,
    int Rating,
    string? Comment,
    DateTime CreatedAt);
