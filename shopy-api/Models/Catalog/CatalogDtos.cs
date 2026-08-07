namespace shopy_api.Models.Catalog;

public record CategoryDto(
    Guid Id,
    string Name,
    string Slug,
    string? ImageUrl,
    Guid? ParentCategoryId);

public record CategoryDetailDto(
    Guid Id,
    string Name,
    string Slug,
    string? ImageUrl,
    Guid? ParentCategoryId,
    IReadOnlyList<CategoryDto> ChildCategories);

public record ProductListItemDto(
    Guid Id,
    string Name,
    string Slug,
    decimal Price,
    string? ImageUrl,
    decimal RatingAverage,
    int RatingCount,
    Guid CategoryId,
    string CategoryName);

public record ProductDetailDto(
    Guid Id,
    string Name,
    string Slug,
    string? Description,
    decimal Price,
    int Stock,
    string? ImageUrl,
    decimal RatingAverage,
    int RatingCount,
    Guid CategoryId,
    string CategoryName,
    DateTime CreatedAt);

public record PagedResult<T>(IReadOnlyList<T> Items, int Page, int PageSize, int TotalCount);

public class ProductQuery
{
    public string? Q { get; set; }
    public Guid? CategoryId { get; set; }
    public string? CategorySlug { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public ProductSort Sort { get; set; } = ProductSort.Newest;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public enum ProductSort
{
    Newest,
    PriceAsc,
    PriceDesc,
    RatingDesc,
}
