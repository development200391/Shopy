namespace shopy_api.Models.Carts;

public record CartItemDto(
    Guid Id,
    Guid ProductId,
    string ProductName,
    string ProductSlug,
    string? ImageUrl,
    decimal Price,
    int Quantity,
    int Stock,
    Guid StoreId,
    string StoreName,
    decimal? OriginalPrice = null);

public record CartDto(Guid Id, IReadOnlyList<CartItemDto> Items);

public record AddCartItemRequest(Guid ProductId, int Quantity = 1);

public record UpdateCartItemRequest(int Quantity);
