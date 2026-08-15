import 'package:dio/dio.dart';

import '../models/catalog/paged_result.dart';
import '../models/moderation/admin_product.dart';
import '../models/moderation/admin_review.dart';
import 'admin_exception.dart';
import 'api_client.dart';

class AdminModerationApiService {
  final ApiClient _apiClient;

  AdminModerationApiService(this._apiClient);

  Future<PagedResult<AdminProductListItem>> getProducts({
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/admin/products',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return PagedResult.fromJson(response.data as Map<String, dynamic>, AdminProductListItem.fromJson);
    } on DioException catch (e) {
      throw AdminException(_extractMessage(e));
    }
  }

  Future<PagedResult<AdminReviewListItem>> getReviews({
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/admin/reviews',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return PagedResult.fromJson(response.data as Map<String, dynamic>, AdminReviewListItem.fromJson);
    } on DioException catch (e) {
      throw AdminException(_extractMessage(e));
    }
  }

  Future<void> takedownProduct(String id) async {
    try {
      await _apiClient.dio.post('/api/admin/products/$id/takedown');
    } on DioException catch (e) {
      throw AdminException(_extractMessage(e));
    }
  }

  Future<void> takedownReview(String id) async {
    try {
      await _apiClient.dio.post('/api/admin/reviews/$id/takedown');
    } on DioException catch (e) {
      throw AdminException(_extractMessage(e));
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
