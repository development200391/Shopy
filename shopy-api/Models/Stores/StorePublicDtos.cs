namespace shopy_api.Models.Stores;

public record StorePublicProfileDto(
    Guid Id,
    string Name,
    string Slug,
    string? Description,
    string? LogoUrl,
    string? BannerUrl,
    string? PhoneNumber,
    decimal RatingAverage,
    int RatingCount,
    int ProductCount,
    int FollowerCount,
    bool IsOpen);
