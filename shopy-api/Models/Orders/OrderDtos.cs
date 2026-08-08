namespace shopy_api.Models.Orders;

public record OrderItemDto(Guid Id, Guid ProductId, string ProductName, decimal UnitPrice, int Quantity, decimal Subtotal);

public record OrderStatusHistoryDto(string Status, DateTime ChangedAt);

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
    decimal Subtotal,
    decimal ShippingCost,
    decimal TotalAmount,
    string? Note,
    OrderAddressSnapshotDto Address,
    IReadOnlyList<OrderItemDto> Items,
    IReadOnlyList<OrderStatusHistoryDto> StatusHistory,
    DateTime CreatedAt,
    DateTime UpdatedAt);

public record CheckoutRequest(Guid AddressId, IReadOnlyList<Guid> CartItemIds, string? Note);

public record UpdateOrderStatusRequest(OrderStatus Status);
