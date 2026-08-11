namespace shopy_api.Models.Sellers;

public record OpenStoreRequest(
    string Name,
    string Slug,
    string? Description,
    string? PhoneNumber,
    // Alamat pickup (langkah 2 di wizard Buka Toko) — dibuat sekalian sebagai StoreAddress
    // default, karena CRUD alamat toko sendiri baru ada di Fase 2.
    string AddressLabel,
    string AddressPicName,
    string AddressPhoneNumber,
    string AddressFullAddress,
    string AddressCity,
    string AddressProvince,
    string AddressPostalCode);

public record StoreSummaryDto(
    Guid Id,
    string Name,
    string Slug,
    string? Description,
    string? LogoUrl,
    string? PhoneNumber,
    string Status,
    bool IsOpen);

public record SellerMeResponse(
    Guid UserId,
    string Email,
    string FullName,
    StoreSummaryDto? Store);

public record StoreDetailDto(
    Guid Id,
    string Name,
    string Slug,
    string? Description,
    string? LogoUrl,
    string? BannerUrl,
    string? PhoneNumber,
    string Status,
    bool IsOpen,
    decimal RatingAverage,
    int RatingCount,
    int ProductCount,
    int FollowerCount);

public record UpdateStoreRequest(
    string Name,
    string? Description,
    string? LogoUrl,
    string? BannerUrl,
    string? PhoneNumber);

public record SetStoreOpenRequest(bool IsOpen);

public record StoreAddressDto(
    Guid Id,
    string Label,
    string PicName,
    string PhoneNumber,
    string FullAddress,
    string City,
    string Province,
    string PostalCode,
    bool IsDefault);

public record SaveStoreAddressRequest(
    string Label,
    string PicName,
    string PhoneNumber,
    string FullAddress,
    string City,
    string Province,
    string PostalCode,
    bool IsDefault = false);

public record BankAccountDto(
    Guid Id,
    string BankCode,
    string BankName,
    string AccountNumber,
    string AccountHolderName,
    bool IsVerified,
    bool IsDefault);

public record SaveBankAccountRequest(
    string BankCode,
    string BankName,
    string AccountNumber,
    string AccountHolderName,
    bool IsDefault = false);

public record StoreDocumentDto(
    Guid Id,
    string Type,
    string FileUrl,
    string Status,
    string? RejectReason,
    DateTime? ReviewedAt);

public record CreateStoreDocumentRequest(string Type, string FileUrl);
