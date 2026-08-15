import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth/auth_response.dart';
import '../models/auth/auth_user.dart';
import '../services/api_client.dart';
import '../services/auth_api_service.dart';
import '../services/auth_exception.dart';
import '../services/jwt_decoder.dart';
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

  /// Dipanggil dari splash screen: cek apakah ada sesi tersimpan. Tidak perlu
  /// cek ulang role di sini — cuma sesi yang lolos cek role Admin di [login]
  /// yang pernah tersimpan (lihat catatan di sana).
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
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    final response = await _authApi.login(email: email, password: password);

    // Cek role SEBELUM sesi disimpan — akun yang bukan Admin tidak boleh
    // pernah punya sesi tersimpan di app ini sama sekali (bukan cuma
    // diarahkan ke halaman lain setelah login, tapi ditolak total). Ini
    // menutup kejadian nyata di app shopy-seller: akun admin sempat berhasil
    // "login" lalu diarahkan ke wizard buka toko karena tidak ada pengecekan
    // role di sisi Flutter.
    if (!JwtDecoder.hasRole(response.accessToken, 'Admin')) {
      throw const AuthException('Akun ini bukan akun admin.');
    }

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
