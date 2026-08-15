import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/shell/admin_home_shell.dart';

/// Dipanggil setelah login sukses (dan dari Splash) — satu-satunya tempat
/// yang memutuskan halaman berikutnya, supaya logic-nya tidak terduplikasi.
///
/// Jauh lebih sederhana dari `shopy-seller`'s versi (tidak ada status
/// toko/verifikasi buat dicek) — begitu [AuthNotifier.login] sukses, role
/// sudah pasti Admin (lihat catatan di `providers/auth_provider.dart`), jadi
/// tinggal langsung ke shell.
Future<void> navigateAfterAuth(BuildContext context, WidgetRef ref) async {
  Navigator.of(
    context,
  ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AdminHomeShell()), (route) => false);
}
