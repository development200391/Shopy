namespace shopy_api.Models.Vouchers;

public record ValidateVoucherRequest(Guid StoreId, string Code, decimal Subtotal, decimal ShippingCost = 0);

public record ValidateVoucherResponse(bool Valid, string? Message, Guid? VoucherId, string? Type, decimal DiscountAmount);
