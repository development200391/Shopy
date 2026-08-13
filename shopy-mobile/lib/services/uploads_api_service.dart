import 'package:dio/dio.dart';

import 'api_client.dart';
import 'chat_exception.dart';

/// Upload generik lintas fitur (lampiran chat, foto ulasan) — `category`:
/// "chat" | "review", lihat `UploadsController` backend.
class UploadsApiService {
  final ApiClient _apiClient;

  UploadsApiService(this._apiClient);

  Future<String> uploadFile(String filePath, String category) async {
    try {
      final formData = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
      final response = await _apiClient.dio.post(
        '/api/uploads',
        data: formData,
        queryParameters: {'category': category},
      );
      return response.data['url'] as String;
    } on DioException catch (e) {
      throw ChatException(_extractMessage(e));
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
