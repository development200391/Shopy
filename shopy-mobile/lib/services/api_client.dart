import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/auth/auth_response.dart';
import 'token_storage_service.dart';

/// Endpoint yang statusnya 401 memang bagian dari respons bisnis normal
/// (mis. salah password / token OAuth invalid), bukan sesi yang kedaluwarsa —
/// jadi tidak boleh memicu auto-refresh.
const _authEndpointsExcludedFromRefresh = [
  '/api/auth/login',
  '/api/auth/refresh',
  '/api/auth/external/google',
  '/api/auth/external/facebook',
];

String resolveApiBaseUrl() {
  const port = 5083;
  if (kIsWeb) return 'http://localhost:$port';
  if (Platform.isAndroid) return 'http://10.0.2.2:$port';
  return 'http://localhost:$port';
}

class ApiClient {
  final Dio dio;
  final TokenStorageService tokenStorage;
  Future<String?>? _refreshFuture;

  ApiClient({required this.tokenStorage})
    : dio = Dio(BaseOptions(baseUrl: resolveApiBaseUrl())) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final alreadyRetried = error.requestOptions.extra['retried'] == true;
          final eligibleForRefresh = !_authEndpointsExcludedFromRefresh.any(path.endsWith);

          if (error.response?.statusCode == 401 && eligibleForRefresh && !alreadyRetried) {
            final newAccessToken = await _refreshAccessToken();
            if (newAccessToken != null) {
              final retryOptions = error.requestOptions
                ..headers['Authorization'] = 'Bearer $newAccessToken'
                ..extra['retried'] = true;
              try {
                final response = await dio.fetch(retryOptions);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  Future<String?> _refreshAccessToken() {
    return _refreshFuture ??= _doRefresh().whenComplete(() => _refreshFuture = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      return null;
    }

    try {
      final response = await Dio(BaseOptions(baseUrl: resolveApiBaseUrl())).post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      await tokenStorage.saveSession(
        accessToken: auth.accessToken,
        accessTokenExpiresAt: auth.accessTokenExpiresAt,
        refreshToken: auth.refreshToken,
        userId: auth.userId,
        email: auth.email,
        fullName: auth.fullName,
      );
      return auth.accessToken;
    } catch (_) {
      await tokenStorage.clear();
      return null;
    }
  }
}
