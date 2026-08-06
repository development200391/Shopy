import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  static const _accessTokenKey = 'access_token';
  static const _accessTokenExpiresAtKey = 'access_token_expires_at';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _userFullNameKey = 'user_full_name';

  final FlutterSecureStorage _storage;

  TokenStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveSession({
    required String accessToken,
    required DateTime accessTokenExpiresAt,
    required String refreshToken,
    required String userId,
    required String email,
    required String fullName,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(
        key: _accessTokenExpiresAtKey,
        value: accessTokenExpiresAt.toIso8601String(),
      ),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userEmailKey, value: email),
      _storage.write(key: _userFullNameKey, value: fullName),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<DateTime?> getAccessTokenExpiresAt() async {
    final value = await _storage.read(key: _accessTokenExpiresAtKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<Map<String, String>?> getStoredUser() async {
    final id = await _storage.read(key: _userIdKey);
    final email = await _storage.read(key: _userEmailKey);
    final fullName = await _storage.read(key: _userFullNameKey);
    if (id == null || email == null || fullName == null) {
      return null;
    }
    return {'id': id, 'email': email, 'fullName': fullName};
  }

  Future<void> updateAccessToken(String accessToken, DateTime expiresAt) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _accessTokenExpiresAtKey, value: expiresAt.toIso8601String()),
    ]);
  }

  Future<void> clear() => _storage.deleteAll();
}
