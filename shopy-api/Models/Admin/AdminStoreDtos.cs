using shopy_api.Models.Sellers;

namespace shopy_api.Models.Admin;

public record AdminStoreListItemDto(
    Guid Id,
    string Name,
    string Slug,
    string OwnerName,
    string OwnerEmail,
    string Status,
    string? ModerationReason,
    int ProductCount,
    DateTime CreatedAt);

public record AdminStoreDetailDto(
    Guid Id,
    string Name,
    string Slug,
    string? Description,
    string? LogoUrl,
    string? BannerUrl,
    string? PhoneNumber,
    string OwnerName,
    string OwnerEmail,
    string Status,
    string? ModerationReason,
    decimal RatingAverage,
    int RatingCount,
    int ProductCount,
    int FollowerCount,
    DateTime CreatedAt,
    IReadOnlyList<StoreDocumentDto> Documents);

public record RejectStoreRequest(string Reason);

public record SuspendStoreRequest(string? Reason);
