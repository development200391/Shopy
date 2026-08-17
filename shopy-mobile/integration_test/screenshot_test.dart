import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:shopy_mobile/main.dart';
import 'package:shopy_mobile/services/token_storage_service.dart';

/// Menangkap tampilan tiap halaman pembeli ke PNG buat direview mata
/// (TASKS.md Fase 7 item #1 & #3).
///
/// App dibungkus `RepaintBoundary` supaya bisa dipanggil `toImage()`. Datanya
/// asli dari backend `localhost:5083` memakai akun test dari TASKS.md.
///
/// Jalankan: `flutter test integration_test/screenshot_test.dart -d windows`
/// (butuh `CMAKE_POLICY_VERSION_MINIMUM=3.5` karena Firebase C++ SDK vs CMake 4 —
/// lihat catatan di `.vscode/launch.json`; dan pastikan tidak ada sesi debug
/// `shopy_mobile.exe` yang masih jalan supaya exe-nya tidak terkunci).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final boundaryKey = GlobalKey();
  final outputDir = Directory('build/ui_review');

  Future<void> pumpFor(WidgetTester tester, Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${outputDir.path}/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    debugPrint('SHOT: $name');
  }

  /// `tester.pageBack()` mencari tombol back gaya Cupertino — app ini Material.
  Future<void> goBack(WidgetTester tester) async {
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await pumpFor(tester, const Duration(seconds: 2));
  }

  /// Bottom nav pembeli memakai `pushReplacement` (bukan `IndexedStack`), jadi
  /// pindah tab = ganti halaman, dan baliknya juga lewat bottom nav.
  Future<void> tapBottomNav(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await pumpFor(tester, const Duration(seconds: 4));
  }

  testWidgets('tangkap semua halaman pembeli', (tester) async {
    await outputDir.create(recursive: true);
    await TokenStorageService().clear();
    await tester.binding.setSurfaceSize(const Size(412, 915));

    await tester.pumpWidget(
      RepaintBoundary(key: boundaryKey, child: const ProviderScope(child: ShopyApp())),
    );

    await pumpFor(tester, const Duration(seconds: 1));
    await shoot(tester, '01_splash');

    await pumpFor(tester, const Duration(seconds: 3));
    await shoot(tester, '02_login');

    const email = String.fromEnvironment('BUYER_EMAIL', defaultValue: 'test@shopy.com');
    const password = String.fromEnvironment('BUYER_PASSWORD', defaultValue: 'Test1234!');
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await pumpFor(tester, const Duration(seconds: 8));
    await shoot(tester, '03_home');

    // Navigasi sengaja HANYA lewat bottom nav (yang memakai `pushReplacement`),
    // tanpa pop sama sekali. Percobaan sebelumnya memakai push + `Navigator.pop`
    // ternyata mem-pop terlalu jauh sampai balik ke halaman login, sehingga
    // screenshot-nya salah halaman. Halaman pencarian ditaruh paling akhir
    // karena dia satu-satunya yang di-push.
    await tapBottomNav(tester, 'Keranjang');
    await shoot(tester, '04_keranjang');

    await tapBottomNav(tester, 'Wishlist');
    await shoot(tester, '05_wishlist');

    await tapBottomNav(tester, 'Home');
    await pumpFor(tester, const Duration(seconds: 2));

    // Search bar di home BUKAN TextField melainkan InkWell berisi teks
    // placeholder, jadi dicari lewat teksnya.
    await tester.tap(find.text('Cari produk favoritmu...'));
    await pumpFor(tester, const Duration(seconds: 4));
    await shoot(tester, '06_cari_produk');

    await tester.binding.setSurfaceSize(null);
  });
}
