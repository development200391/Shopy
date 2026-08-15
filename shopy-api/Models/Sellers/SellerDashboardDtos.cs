namespace shopy_api.Models.Sellers;

public record NeedsFollowUpDto(int NewOrders, int ReadyToShip, int LowStockCount, int UnrepliedReviews);

public record DailySalesDto(DateTime Date, decimal Total);

public record SellerDashboardDto(
    decimal AvailableBalance,
    decimal PendingBalance,
    int NewOrders,
    int ProductsSoldToday,
    int StoreVisitors,
    decimal IncomeToday,
    NeedsFollowUpDto NeedsFollowUp,
    IReadOnlyList<DailySalesDto> Sales7Days);
