using shopy_api.Models.Orders;

namespace shopy_api.Models.Sellers;

public record BuyerInfoDto(string FullName, int JoinedYear, int OrderCountAtThisStore);

public record SellerSubOrderListItemDto(
    Guid Id,
    string SubOrderNumber,
    string Status,
    string BuyerName,
    int ItemCount,
    IReadOnlyList<string?> PreviewImageUrls,
    decimal TotalAmount,
    DateTime? AutoCancelAt,
    DateTime CreatedAt);

public record SellerSubOrderDetailDto(
    Guid Id,
    string SubOrderNumber,
    string Status,
    BuyerInfoDto Buyer,
    OrderAddressSnapshotDto Address,
    IReadOnlyList<OrderItemDto> Items,
    decimal Subtotal,
    decimal ShippingCost,
    decimal VoucherDiscount,
    decimal CommissionAmount,
    decimal SellerEarning,
    decimal TotalAmount,
    string? CourierCode,
    string? CourierService,
    string? TrackingNumber,
    string? ProofPhotoUrl,
    string? Note,
    string? CancelReason,
    DateTime? AutoCancelAt,
    IReadOnlyList<SubOrderStatusHistoryDto> StatusHistory,
    DateTime CreatedAt);

public record RejectSubOrderRequest(string Reason);

public record ShipSubOrderRequest(string CourierCode, string CourierService, string TrackingNumber, string? ProofPhotoUrl);
