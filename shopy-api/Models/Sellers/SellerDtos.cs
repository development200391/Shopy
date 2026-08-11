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
