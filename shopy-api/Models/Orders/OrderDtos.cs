namespace shopy_api.Models.Orders;

public record OrderItemDto(Guid Id, Guid ProductId, string ProductName, decimal UnitPrice, int Quantity, decimal Subtotal);

public record OrderAddressSnapshotDto(
    string RecipientName, string PhoneNumber, string FullAddress, string City, string Province, string PostalCode);

public record OrderSummaryDto(
    Guid Id,
    string OrderNumber,
    string Status,
    decimal TotalAmount,
    int ItemCount,
    IReadOnlyList<string?> PreviewImageUrls,
    DateTime CreatedAt);

public record OrderDetailDto(
    Guid Id,
    string OrderNumber,
    string Status,
    decimal TotalAmount,
    string? Note,
    OrderAddressSnapshotDto Address,
    IReadOnlyList<SubOrderSummaryDto> SubOrders,
    DateTime CreatedAt);

public record CheckoutVoucherDto(Guid StoreId, string Code);

public record CheckoutRequest(
    Guid AddressId, IReadOnlyList<Guid> CartItemIds, string? Note, IReadOnlyList<CheckoutVoucherDto>? Vouchers = null);
