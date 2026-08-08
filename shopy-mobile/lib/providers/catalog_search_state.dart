import '../models/catalog/product_sort.dart';
import '../models/catalog/product_summary.dart';

class ProductSearchState {
  final String query;
  final String? categoryId;
  final String? categoryName;
  final int? minPrice;
  final int? maxPrice;
  final ProductSort sort;
  final List<ProductSummary> items;
  final int page;
  final int totalCount;
  final bool hasMore;
  final bool loading;
  final String? error;

  const ProductSearchState({
    this.query = '',
    this.categoryId,
    this.categoryName,
    this.minPrice,
    this.maxPrice,
    this.sort = ProductSort.newest,
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.hasMore = false,
    this.loading = false,
    this.error,
  });

  bool get hasPriceFilter => minPrice != null || maxPrice != null;

  ProductSearchState copyWith({
    String? query,
    String? categoryId,
    String? categoryName,
    bool clearCategory = false,
    int? minPrice,
    bool clearMinPrice = false,
    int? maxPrice,
    bool clearMaxPrice = false,
    ProductSort? sort,
    List<ProductSummary>? items,
    int? page,
    int? totalCount,
    bool? hasMore,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return ProductSearchState(
      query: query ?? this.query,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory ? null : (categoryName ?? this.categoryName),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      sort: sort ?? this.sort,
      items: items ?? this.items,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
