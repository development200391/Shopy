import 'package:dio/dio.dart';

import '../models/catalog/paged_result.dart';
import '../models/store/admin_store.dart';
import 'admin_exception.dart';
import 'api_client.dart';

class AdminStoreApiService {
  final ApiClient _apiClient;

  AdminStoreApiService(this._apiClient);

  Future<PagedResult<AdminStoreListItem>> getStores({
    String? status,
    String? q,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/admin/stores',
        queryParameters: {
          if (status != null) 'status': status,
          if (q != null && q.isNotEmpty) 'q': q,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return PagedResult.fromJson(response.data as Map<String, dynamic>, AdminStoreListItem.fromJson);
    } on DioException catch (e) {
      throw AdminException(_extractMessage(e));
    }
  }

  Future<AdminStoreDetail> getStore(String id) async {
    try {
      final response = await _apiClient.dio.get('/api/admin/stores/$id');
      return AdminStoreDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AdminException(_extractMessage(e));
    }
  }

  Future<void> approve(String id) async {
    try {
      await _apiClient.dio.post('/api/admin/stores/$id/approve');
    } on DioException catch (e) {
      throw AdminException(_extractMessage(e));
    }
  }

  Future<void> reject(String id, String reason) async {
    try {
      await _apiClient.dio.post('/api/admin/stores/$id/reject', data: {'reason': reason});
    } on DioException catch (e) {
      throw AdminException(_extractMessage(e));
    }
  }

  Future<void> suspend(String id, String? reason) async {
    try {
      await _apiClient.dio.post('/api/admin/stores/$id/suspend', data: {'reason': reason});
    } on DioException catch (e) {
      throw AdminException(_extractMessage(e));
    }
  }

  Future<void> activate(String id) async {
    try {
      await _apiClient.dio.post('/api/admin/stores/$id/activate');
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
