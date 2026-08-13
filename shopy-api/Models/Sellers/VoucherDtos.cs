namespace shopy_api.Models.Sellers;

public record VoucherDto(
    Guid Id,
    string Code,
    string Type,
    decimal Value,
    decimal? MaxDiscount,
    decimal? MinPurchase,
    int? Quota,
    int UsedCount,
    DateTime StartAt,
    DateTime EndAt,
    bool IsActive,
    // Status terhitung dari tanggal+kuota, independen dari toggle IsActive — lihat TASKSELLER.md Fase 6.
    string Status,
    decimal TotalDiscountGiven,
    decimal TotalOrderValue);

public record SaveVoucherRequest(
    string Code,
    string Type,
    decimal Value,
    decimal? MaxDiscount,
    decimal? MinPurchase,
    int? Quota,
    DateTime StartAt,
    DateTime EndAt);

public record SetVoucherActiveRequest(bool IsActive);
