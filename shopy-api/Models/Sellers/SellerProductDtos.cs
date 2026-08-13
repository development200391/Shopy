namespace shopy_api.Models.Sellers;

public record ProductImageDto(Guid Id, string Url, int SortOrder, bool IsPrimary);

public record SellerProductListItemDto(
    Guid Id,
    string Name,
    string Slug,
    decimal Price,
    string? ImageUrl,
    int Stock,
    bool IsActive,
    int SoldCount);

public record SellerProductDetailDto(
    Guid Id,
    string Name,
    string Slug,
    string? Description,
    decimal Price,
    int Stock,
    int Weight,
    string Condition,
    Guid CategoryId,
    string CategoryName,
    bool IsActive,
    IReadOnlyList<ProductImageDto> Images);

public record SaveProductRequest(
    string Name,
    Guid CategoryId,
    decimal Price,
    int Stock,
    int Weight,
    string Condition,
    string? Description,
    IReadOnlyList<string> ImageUrls,
    bool IsActive);

public record SetProductActiveRequest(bool IsActive);

public record BulkUpdateProductItem(Guid Id, decimal Price, int Stock);

public record BulkUpdateProductsRequest(IReadOnlyList<BulkUpdateProductItem> Items);

public record LowStockProductDto(Guid Id, string Name, int Stock, string? ImageUrl);
