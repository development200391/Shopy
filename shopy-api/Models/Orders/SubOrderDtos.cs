using shopy_api.Models;

namespace shopy_api.Models.Orders;

public record SubOrderStatusHistoryDto(string Status, string? Note, DateTime ChangedAt);

public record SubOrderSummaryDto(
    Guid Id,
    string SubOrderNumber,
    Guid OrderId,
    string OrderNumber,
    Guid StoreId,
    string StoreName,
    string? StoreLogoUrl,
    string Status,
    decimal Subtotal,
    decimal ShippingCost,
    decimal VoucherDiscount,
    decimal TotalAmount,
    int ItemCount,
    IReadOnlyList<string?> PreviewImageUrls,
    DateTime CreatedAt);

public record SubOrderDetailDto(
    Guid Id,
    string SubOrderNumber,
    Guid OrderId,
    string OrderNumber,
    Guid StoreId,
    string StoreName,
    string? StoreLogoUrl,
    string Status,
    decimal Subtotal,
    decimal ShippingCost,
    decimal VoucherDiscount,
    decimal TotalAmount,
    string? CourierCode,
    string? CourierService,
    string? TrackingNumber,
    OrderAddressSnapshotDto Address,
    string? Note,
    IReadOnlyList<OrderItemDto> Items,
    IReadOnlyList<SubOrderStatusHistoryDto> StatusHistory,
    DateTime CreatedAt);

public record UpdateSubOrderStatusRequest(SubOrderStatus Status);
