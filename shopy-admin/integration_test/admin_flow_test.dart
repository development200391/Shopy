import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:shopy_admin/main.dart' as app;
import 'package:shopy_admin/screens/shell/admin_home_shell.dart';
import 'package:shopy_admin/services/token_storage_service.dart';

/// Integration test end-to-end (TASKADMIN.md Fase 7) — menjalankan app Windows
/// ASLI dan menggerakkan UI-nya beneran (ketik, tap, pindah tab) sambil memanggil
/// backend `shopy-api` yang harus sudah jalan di `localhost:5083`.
///
/// Beda dari `test/widget_test.dart` yang memalsukan `AuthNotifier`: di sini
/// semua lapisan asli — `flutter_secure_storage` beneran nulis ke Credential
/// Manager Windows, `Dio` beneran kirim HTTP. Ini satu-satunya cara membuktikan
/// lapisan UI benar-benar tersambung ke API, yang tidak bisa dibuktikan curl.
///
/// Jalankan: `flutter test integration_test/admin_flow_test.dart -d windows`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Splash memakai animasi `repeat()` yang tidak pernah selesai, jadi
  /// `pumpAndSettle()` akan hang selamanya di sana — pakai pump berjangka.
  Future<void> pumpFor(WidgetTester tester, Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> loginAsAdmin(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'admin-demo@shopy.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'AdminDemo1234!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    // Tunggu HTTP login + navigasi ke shell.
    await pumpFor(tester, const Duration(seconds: 6));
  }

  testWidgets('login admin lalu keliling 4 tab, semua memuat data asli', (tester) async {
    // Mulai dari kondisi bersih supaya tidak ke-auto-login sesi run sebelumnya.
    await TokenStorageService().clear();

    app.main();
    await pumpFor(tester, const Duration(seconds: 4)); // splash 1400ms + bootstrap

    // --- Halaman Login ---
    expect(find.text('Khusus akun admin — akun lain akan ditolak'), findsOneWidget,
        reason: 'harusnya mendarat di LoginScreen setelah storage dibersihkan');

    await loginAsAdmin(tester);

    // --- Shell ---
    expect(find.byType(AdminHomeShell), findsOneWidget, reason: 'login admin harus masuk ke shell');
    expect(find.byType(NavigationBar), findsOneWidget);

    // --- Tab 1: Toko (default) ---
    // Data dimuat dari GET /api/admin/stores yang asli.
    expect(find.text('Verifikasi Toko'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: 'list toko harus sudah selesai memuat, tidak nyangkut di loading');

    // --- Tab 2: Pencairan ---
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Pencairan')));
    await pumpFor(tester, const Duration(seconds: 4));
    expect(find.text('Pencairan Dana'), findsOneWidget);

    // --- Tab 3: Moderasi ---
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Moderasi')));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('Cari Produk'), findsOneWidget);
    expect(find.text('Cari Ulasan'), findsOneWidget);

    // Masuk ke halaman Cari Produk (memanggil GET /api/admin/products asli).
    await tester.tap(find.text('Cari Produk'));
    await pumpFor(tester, const Duration(seconds: 4));
    expect(find.widgetWithText(TextField, 'Cari produk atau toko...'), findsOneWidget);
    await tester.pageBack();
    await pumpFor(tester, const Duration(seconds: 2));

    // --- Tab 4: Lainnya ---
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Lainnya')));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('Pengaturan Platform'), findsOneWidget);
    expect(find.text('Keluar Akun'), findsOneWidget);

    // Buka Pengaturan Platform (memanggil GET /api/admin/settings asli).
    await tester.tap(find.text('Pengaturan Platform'));
    await pumpFor(tester, const Duration(seconds: 4));
    expect(find.text('Persentase Komisi'), findsOneWidget,
        reason: 'form pengaturan harus terisi dari data backend asli');
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pageBack();
    await pumpFor(tester, const Duration(seconds: 2));

    // --- Logout ---
    await tester.tap(find.text('Keluar Akun'));
    await pumpFor(tester, const Duration(seconds: 3));
    expect(find.text('Khusus akun admin — akun lain akan ditolak'), findsOneWidget,
        reason: 'logout harus balik ke LoginScreen');
  });
}
