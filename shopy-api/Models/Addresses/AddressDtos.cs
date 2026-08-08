namespace shopy_api.Models.Addresses;

public record AddressDto(
    Guid Id,
    string Label,
    string RecipientName,
    string PhoneNumber,
    string FullAddress,
    string City,
    string Province,
    string PostalCode,
    bool IsDefault);

public record SaveAddressRequest(
    string Label,
    string RecipientName,
    string PhoneNumber,
    string FullAddress,
    string City,
    string Province,
    string PostalCode,
    bool IsDefault = false);
