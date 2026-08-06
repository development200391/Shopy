import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth/auth_response.dart';
import '../models/auth/auth_user.dart';
import '../services/api_client.dart';
import '../services/auth_api_service.dart';
import '../services/token_storage_service.dart';
import 'auth_state.dart';

final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageServiceProvider));
});

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.watch(apiClientProvider));
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.unknown();

  TokenStorageService get _tokenStorage => ref.read(tokenStorageServiceProvider);
  AuthApiService get _authApi => ref.read(authApiServiceProvider);

  /// Dipanggil dari splash screen: cek apakah ada sesi tersimpan.
  /// Validasi/refresh token yang benar-benar terjadi ditangani otomatis oleh
  /// interceptor Dio saat request pertama ke API dilakukan (bukan di sini).
  Future<void> bootstrap() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      final storedUser = await _tokenStorage.getStoredUser();

      if (refreshToken == null || storedUser == null) {
        state = const AuthState.unauthenticated();
        return;
      }

      state = AuthState.authenticated(
        AuthUser(
          id: storedUser['id']!,
          email: storedUser['email']!,
          fullName: storedUser['fullName']!,
        ),
      );
    } catch (_) {
      // Storage tidak terbaca (mis. platform channel belum siap) — anggap belum login.
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    final response = await _authApi.login(email: email, password: password);
    await _persistSession(response);
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    final response = await _authApi.register(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
    await _persistSession(response);
  }

  Future<void> loginWithGoogle(String idToken) async {
    final response = await _authApi.loginWithGoogle(idToken);
    await _persistSession(response);
  }

  Future<void> loginWithFacebook(String accessToken) async {
    final response = await _authApi.loginWithFacebook(accessToken);
    await _persistSession(response);
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    state = const AuthState.unauthenticated();
  }

  Future<void> _persistSession(AuthResponse response) async {
    await _tokenStorage.saveSession(
      accessToken: response.accessToken,
      accessTokenExpiresAt: response.accessTokenExpiresAt,
      refreshToken: response.refreshToken,
      userId: response.userId,
      email: response.email,
      fullName: response.fullName,
    );
    state = AuthState.authenticated(
      AuthUser(id: response.userId, email: response.email, fullName: response.fullName),
    );
  }
}
