import 'package:dio/dio.dart';

import '../models/catalog/paged_result.dart';
import '../models/notification/app_notification.dart';
import 'api_client.dart';
import 'notification_exception.dart';

class NotificationApiService {
  final ApiClient _apiClient;

  NotificationApiService(this._apiClient);

  Future<PagedResult<AppNotification>> getNotifications({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/notifications',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(response.data as Map<String, dynamic>, AppNotification.fromJson);
    } on DioException catch (e) {
      throw NotificationException(_extractMessage(e));
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/api/notifications/unread-count');
      return response.data as int;
    } on DioException catch (e) {
      throw NotificationException(_extractMessage(e));
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _apiClient.dio.patch('/api/notifications/$id/read');
    } on DioException catch (e) {
      throw NotificationException(_extractMessage(e));
    }
  }

  Future<void> markAllRead() async {
    try {
      await _apiClient.dio.post('/api/notifications/read-all');
    } on DioException catch (e) {
      throw NotificationException(_extractMessage(e));
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
