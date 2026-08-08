import 'package:dio/dio.dart';

import '../models/catalog/category.dart';
import '../models/catalog/paged_result.dart';
import '../models/catalog/product_detail.dart';
import '../models/catalog/product_sort.dart';
import '../models/catalog/product_summary.dart';
import 'api_client.dart';
import 'catalog_exception.dart';

class CatalogApiService {
  final ApiClient _apiClient;

  CatalogApiService(this._apiClient);

  Future<List<Category>> getRootCategories() async {
    try {
      final response = await _apiClient.dio.get('/api/categories');
      return (response.data as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw CatalogException(_extractMessage(e));
    }
  }

  Future<PagedResult<ProductSummary>> getProducts({
    String? q,
    String? categoryId,
    String? categorySlug,
    int? minPrice,
    int? maxPrice,
    ProductSort sort = ProductSort.newest,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/products',
        queryParameters: {
          if (q != null && q.isNotEmpty) 'q': q,
          if (categoryId != null) 'categoryId': categoryId,
          if (categorySlug != null) 'categorySlug': categorySlug,
          if (minPrice != null) 'minPrice': minPrice,
          if (maxPrice != null) 'maxPrice': maxPrice,
          'sort': sort.queryValue,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return PagedResult.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ProductSummary.fromJson(json),
      );
    } on DioException catch (e) {
      throw CatalogException(_extractMessage(e));
    }
  }

  Future<ProductDetail> getProductBySlug(String slug) async {
    try {
      final response = await _apiClient.dio.get('/api/products/$slug');
      return ProductDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw CatalogException(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
