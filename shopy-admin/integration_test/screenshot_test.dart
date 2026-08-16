import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:shopy_admin/main.dart';
import 'package:shopy_admin/services/token_storage_service.dart';

/// Menangkap tampilan tiap halaman ke PNG buat direview mata (TASKADMIN.md Fase 7).
///
/// Bedanya dari `admin_flow_test.dart`: di sini app dibungkus `RepaintBoundary`
/// supaya bisa dipanggil `toImage()`. Datanya tetap asli dari backend, dan ukuran
/// surface dipaksa seukuran HP karena UI ini memang didesain mobile-first
/// walaupun sekarang dijalankan di Windows.
///
/// Jalankan: `flutter test integration_test/screenshot_test.dart -d windows`
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

  /// `tester.pageBack()` mencari tombol back gaya Cupertino — tidak ada di app
  /// Material ini. Pop langsung lewat Navigator jauh lebih andal.
  Future<void> goBack(WidgetTester tester) async {
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    final end = DateTime.now().add(const Duration(seconds: 2));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${outputDir.path}/$name.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    debugPrint('SHOT: ${file.absolute.path}');
  }

  testWidgets('tangkap semua halaman admin', (tester) async {
    await outputDir.create(recursive: true);
    await TokenStorageService().clear();
    // Ukuran logis HP biasa — UI ini mobile-first.
    await tester.binding.setSurfaceSize(const Size(412, 915));

    await tester.pumpWidget(
      RepaintBoundary(key: boundaryKey, child: const ProviderScope(child: ShopyAdminApp())),
    );

    await pumpFor(tester, const Duration(seconds: 1));
    await shoot(tester, '01_splash');

    await pumpFor(tester, const Duration(seconds: 3));
    await shoot(tester, '02_login');

    await tester.enterText(find.byType(TextFormField).at(0), 'admin-demo@shopy.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'AdminDemo1234!');
    await pumpFor(tester, const Duration(milliseconds: 500));
    await shoot(tester, '03_login_terisi');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await pumpFor(tester, const Duration(seconds: 6));
    await shoot(tester, '04_tab_toko');

    // Detail toko pertama (kalau ada datanya). Sengaja pakai ikon kartu toko, BUKAN
    // `InkWell` pertama di dalam `ListView` — baris filter chip juga sebuah ListView
    // horizontal, jadi `.first` malah kena chip "Semua". Tab Toko sedang terpilih
    // sehingga NavigationBar memakai ikon `storefront` (isi), berarti semua
    // `storefront_outlined` yang tersisa pasti milik kartu toko.
    final firstStore = find.byIcon(Icons.storefront_outlined);
    if (firstStore.evaluate().isNotEmpty) {
      await tester.tap(firstStore.first);
      await pumpFor(tester, const Duration(seconds: 4));
      await shoot(tester, '05_detail_toko');
      await goBack(tester);
    }

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Pencairan')));
    await pumpFor(tester, const Duration(seconds: 4));
    await shoot(tester, '06_tab_pencairan');

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Moderasi')));
    await pumpFor(tester, const Duration(seconds: 2));
    await shoot(tester, '07_tab_moderasi');

    await tester.tap(find.text('Cari Produk'));
    await pumpFor(tester, const Duration(seconds: 4));
    await shoot(tester, '08_cari_produk');
    await goBack(tester);

    await tester.tap(find.text('Cari Ulasan'));
    await pumpFor(tester, const Duration(seconds: 4));
    await shoot(tester, '09_cari_ulasan');
    await goBack(tester);

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Lainnya')));
    await pumpFor(tester, const Duration(seconds: 2));
    await shoot(tester, '10_tab_lainnya');

    await tester.tap(find.text('Pengaturan Platform'));
    await pumpFor(tester, const Duration(seconds: 4));
    await shoot(tester, '11_pengaturan_platform');
    await goBack(tester);

    await tester.tap(find.text('Broadcast Promo'));
    await pumpFor(tester, const Duration(seconds: 3));
    await shoot(tester, '12_broadcast_promo');
    await goBack(tester);

    await tester.binding.setSurfaceSize(null);
  });
}
