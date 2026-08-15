import 'package:dio/dio.dart';

import '../models/settings/platform_settings.dart';
import 'admin_exception.dart';
import 'api_client.dart';

class AdminSettingsApiService {
  final ApiClient _apiClient;

  AdminSettingsApiService(this._apiClient);

  Future<PlatformSettings> getSettings() async {
    try {
      final response = await _apiClient.dio.get('/api/admin/settings');
      return PlatformSettings.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AdminException(_extractMessage(e));
    }
  }

  Future<PlatformSettings> updateSettings({
    required double commissionPercent,
    required int withdrawalAdminFee,
    required int minWithdrawal,
    required int maxWithdrawalsPerDay,
    required int autoCancelHours,
    required int autoCompleteDays,
    required int lowStockThreshold,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/admin/settings',
        data: {
          'commissionPercent': commissionPercent,
          'withdrawalAdminFee': withdrawalAdminFee,
          'minWithdrawal': minWithdrawal,
          'maxWithdrawalsPerDay': maxWithdrawalsPerDay,
          'autoCancelHours': autoCancelHours,
          'autoCompleteDays': autoCompleteDays,
          'lowStockThreshold': lowStockThreshold,
        },
      );
      return PlatformSettings.fromJson(response.data as Map<String, dynamic>);
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
