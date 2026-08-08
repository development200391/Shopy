namespace shopy_api.Models.Wishlists;

public record WishlistItemDto(
    Guid Id,
    Guid ProductId,
    string ProductName,
    string ProductSlug,
    string? ImageUrl,
    decimal Price,
    decimal RatingAverage);

public record AddWishlistItemRequest(Guid ProductId);
