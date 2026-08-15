namespace shopy_api.Models.Sellers;

public record StatisticsMetricDto(decimal Value, decimal DeltaPercent);

public record TopProductDto(Guid ProductId, string ProductName, string? ImageUrl, int QuantitySold, decimal Revenue);

public record SellerStatisticsDto(
    DateTime PeriodStart,
    DateTime PeriodEnd,
    StatisticsMetricDto Omzet,
    StatisticsMetricDto OrderCount,
    StatisticsMetricDto ProductsSold,
    StatisticsMetricDto AverageOrder,
    IReadOnlyList<DailySalesDto> DailySeries,
    IReadOnlyList<TopProductDto> TopProducts);
