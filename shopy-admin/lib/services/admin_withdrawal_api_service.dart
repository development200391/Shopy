import 'package:dio/dio.dart';

import '../models/catalog/paged_result.dart';
import '../models/withdrawal/admin_withdrawal.dart';
import 'admin_exception.dart';
import 'api_client.dart';

class AdminWithdrawalApiService {
  final ApiClient _apiClient;

  AdminWithdrawalApiService(this._apiClient);

  Future<PagedResult<AdminWithdrawalListItem>> getWithdrawals({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/admin/withdrawals',
        queryParameters: {if (status != null) 'status': status, 'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(response.data as Map<String, dynamic>, AdminWithdrawalListItem.fromJson);
    } on DioException catch (e) {
      throw AdminException(_extractMessage(e));
    }
  }

  Future<void> updateStatus(String id, AdminWithdrawalStatus status, {String? reason}) async {
    try {
      await _apiClient.dio.patch(
        '/api/admin/withdrawals/$id',
        data: {'status': status.apiValue, if (reason != null) 'reason': reason},
      );
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
