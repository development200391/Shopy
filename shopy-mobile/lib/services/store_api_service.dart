import 'package:dio/dio.dart';

import '../models/catalog/paged_result.dart';
import '../models/catalog/product_summary.dart';
import '../models/store/store_public_profile.dart';
import 'api_client.dart';
import 'store_exception.dart';

class StoreApiService {
  final ApiClient _apiClient;

  StoreApiService(this._apiClient);

  Future<StorePublicProfile> getStoreBySlug(String slug) async {
    try {
      final response = await _apiClient.dio.get('/api/stores/$slug');
      return StorePublicProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw StoreException(_extractMessage(e));
    }
  }

  Future<PagedResult<ProductSummary>> getStoreProducts(
    String slug, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/stores/$slug/products',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ProductSummary.fromJson(json),
      );
    } on DioException catch (e) {
      throw StoreException(_extractMessage(e));
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
