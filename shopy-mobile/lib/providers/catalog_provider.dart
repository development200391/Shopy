import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog/category.dart';
import '../models/catalog/product_sort.dart';
import '../models/catalog/product_summary.dart';
import '../services/catalog_api_service.dart';
import 'auth_provider.dart';
import 'catalog_search_state.dart';

final catalogApiServiceProvider = Provider<CatalogApiService>((ref) {
  return CatalogApiService(ref.watch(apiClientProvider));
});

/// Riverpod 3 otomatis retry provider yang error (backoff sampai puluhan
/// detik) — dimatikan di sini karena UI katalog sudah punya tombol
/// "Coba lagi" manual sendiri, jadi error sebaiknya langsung tampil.
Duration? _noRetry(int retryCount, Object error) => null;

/// Kategori root untuk section "Kategori" di Home.
final homeCategoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(catalogApiServiceProvider).getRootCategories();
}, retry: _noRetry);

/// Produk untuk section "Produk Populer" di Home — diurutkan berdasarkan rating.
final popularProductsProvider = FutureProvider<List<ProductSummary>>((ref) async {
  final result = await ref
      .watch(catalogApiServiceProvider)
      .getProducts(sort: ProductSort.ratingDesc, pageSize: 4);
  return result.items;
}, retry: _noRetry);

/// Detail 1 produk berdasarkan slug, dipakai halaman Detail Produk.
final productDetailProvider = FutureProvider.family((ref, String slug) {
  return ref.watch(catalogApiServiceProvider).getProductBySlug(slug);
}, retry: _noRetry);

final productSearchProvider = NotifierProvider<ProductSearchNotifier, ProductSearchState>(
  ProductSearchNotifier.new,
);

class ProductSearchNotifier extends Notifier<ProductSearchState> {
  static const int _pageSize = 20;

  @override
  ProductSearchState build() => const ProductSearchState();

  CatalogApiService get _api => ref.read(catalogApiServiceProvider);

  /// Dipanggil sekali saat halaman Search & Filter dibuka, mis. dari kategori
  /// di Home (`categoryId`/`categoryName` terisi) atau dari search bar (`query`).
  Future<void> init({String? query, String? categoryId, String? categoryName}) {
    state = ProductSearchState(
      query: query ?? '',
      categoryId: categoryId,
      categoryName: categoryName,
    );
    return _fetch(resetItems: true);
  }

  Future<void> search(String query) {
    state = state.copyWith(query: query);
    return _fetch(resetItems: true);
  }

  Future<void> setSort(ProductSort sort) {
    state = state.copyWith(sort: sort);
    return _fetch(resetItems: true);
  }

  Future<void> setPriceRange({int? minPrice, int? maxPrice}) {
    state = state.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
      clearMinPrice: minPrice == null,
      clearMaxPrice: maxPrice == null,
    );
    return _fetch(resetItems: true);
  }

  Future<void> clearCategory() {
    state = state.copyWith(clearCategory: true);
    return _fetch(resetItems: true);
  }

  Future<void> loadMore() {
    if (state.loading || !state.hasMore) return Future.value();
    return _fetch(resetItems: false);
  }

  Future<void> _fetch({required bool resetItems}) async {
    final nextPage = resetItems ? 1 : state.page + 1;
    state = state.copyWith(loading: true, clearError: true);

    try {
      final result = await _api.getProducts(
        q: state.query,
        categoryId: state.categoryId,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
        sort: state.sort,
        page: nextPage,
        pageSize: _pageSize,
      );
      state = state.copyWith(
        items: resetItems ? result.items : [...state.items, ...result.items],
        page: result.page,
        totalCount: result.totalCount,
        hasMore: result.hasMore,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
