import 'dart:convert';

/// Decode payload JWT tanpa verifikasi signature — cukup buat baca claim
/// (mis. `role`) demi keputusan routing di Flutter. Signature/keabsahan token
/// tetap sepenuhnya tanggung jawab backend (`[Authorize(Roles=...)]`), jadi
/// tidak masalah kalau token dipalsukan di sisi client: request ke API asli
/// tetap akan ditolak sana.
class JwtDecoder {
  static Map<String, dynamic> decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Token JWT tidak valid.');
    }
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return jsonDecode(payload) as Map<String, dynamic>;
  }

  /// User bisa punya lebih dari 1 role (mis. akun yang pernah dipakai buka
  /// toko lewat `shopy-seller` selain jadi admin) — backend menyisipkan 1
  /// claim `role` per role yang dipunya, yang begitu di-serialize ke JSON
  /// payload JWT jadi array kalau lebih dari satu, atau string tunggal kalau
  /// cuma satu. Jangan asumsikan salah satu bentuk saja.
  static bool hasRole(String token, String role) {
    try {
      final claim = decode(token)['role'];
      if (claim is List) {
        return claim.contains(role);
      }
      return claim == role;
    } catch (_) {
      return false;
    }
  }
}
