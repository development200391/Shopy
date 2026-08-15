import 'package:dio/dio.dart';

import 'api_client.dart';

/// Kegagalan daftar/hapus device token sengaja tidak dilempar sebagai exception
/// ke pemanggil (lihat `PushNotificationService`) — device token cuma pelengkap
/// push notification, gagal daftar tidak boleh mengganggu alur login/app utama.
class DeviceTokenApiService {
  final ApiClient _apiClient;

  DeviceTokenApiService(this._apiClient);

  Future<void> register(String token) async {
    try {
      // `appType: 'Seller'` — TASKSELLER.md Fase 8, supaya push seller tidak
      // nyasar ke app pembeli kalau 1 akun login di kedua app.
      await _apiClient.dio.post('/api/device-tokens', data: {'token': token, 'appType': 'Seller'});
    } on DioException {
      // Diamkan — lihat catatan di atas.
    }
  }

  Future<void> unregister(String token) async {
    try {
      await _apiClient.dio.delete('/api/device-tokens/${Uri.encodeComponent(token)}');
    } on DioException {
      // Diamkan — lihat catatan di atas.
    }
  }
}
