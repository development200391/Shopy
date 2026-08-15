import 'package:dio/dio.dart';

import 'admin_exception.dart';
import 'api_client.dart';

class AdminBroadcastApiService {
  final ApiClient _apiClient;

  AdminBroadcastApiService(this._apiClient);

  Future<int> broadcastPromo({required String title, required String body}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/notifications/promo',
        data: {'title': title, 'body': body},
      );
      return (response.data as Map<String, dynamic>)['recipientCount'] as int;
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
