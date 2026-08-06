import 'package:dio/dio.dart';

import '../models/auth/auth_response.dart';
import 'api_client.dart';
import 'auth_exception.dart';

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService(this._apiClient);

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) {
    return _post('/api/auth/register', {
      'email': email,
      'password': password,
      'fullName': fullName,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
    });
  }

  Future<AuthResponse> login({required String email, required String password}) {
    return _post('/api/auth/login', {'email': email, 'password': password});
  }

  Future<AuthResponse> loginWithGoogle(String idToken) {
    return _post('/api/auth/external/google', {'idToken': idToken});
  }

  Future<AuthResponse> loginWithFacebook(String accessToken) {
    return _post('/api/auth/external/facebook', {'accessToken': accessToken});
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.dio.post('/api/auth/forgot-password', data: {'email': email});
  }

  Future<bool> verifyResetCode({required String email, required String code}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/verify-reset-code',
        data: {'email': email, 'code': code},
      );
      return response.data['valid'] == true;
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _apiClient.dio.post(
        '/api/auth/reset-password',
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  Future<AuthResponse> _post(String path, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(path, data: data);
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['message'] is String) {
        return data['message'] as String;
      }
      if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        return (data['errors'] as List).join(', ');
      }
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
