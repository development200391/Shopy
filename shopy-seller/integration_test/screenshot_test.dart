import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:shopy_seller/main.dart';
import 'package:shopy_seller/services/token_storage_service.dart';

/// Menangkap tampilan tiap halaman seller ke PNG buat dibandingkan dengan mockup
/// di `design/assets/` (TASKSELLER.md Fase 10 item #1).
///
/// App dibungkus `RepaintBoundary` supaya bisa dipanggil `toImage()`. Datanya
/// asli dari backend `localhost:5083`, jadi backend harus sudah jalan.
///
/// ⚠️ Akun sengaja BUKAN `seller-demo@shopy.com` yang tertulis di TASKSELLER.md:
/// akun itu ternyata tidak pernah ada di DB ini. `CatalogSeeder.SeedAsync`
/// berhenti lebih awal kalau tabel `Categories` sudah terisi, dan kategori sudah
/// di-seed jauh sebelum kode akun demo seller ditambahkan — jadi
/// `EnsureDemoStoreAsync` tidak pernah jalan. Lihat TASKSELLER.md Fase 10 item #6.
/// Kredensial bisa ditimpa lewat `--dart-define` kalau akun di bawah ikut hilang.
///
/// Jalankan: `flutter test integration_test/screenshot_test.dart -d windows`
/// (pastikan tidak ada sesi debug `shopy_seller.exe` yang masih jalan — exe-nya
/// akan terkunci dan build gagal).
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

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
    await pumpFor(tester, const Duration(seconds: 4));
  }

  /// Menu di tab Toko panjang — sebagian butuh di-scroll dulu sebelum bisa di-tap.
  Future<void> openStoreMenu(WidgetTester tester, String label, String shotName) async {
    final target = find.text(label);
    await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).last);
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(target);
    await pumpFor(tester, const Duration(seconds: 4));
    await shoot(tester, shotName);
    await goBack(tester);
  }

  testWidgets('tangkap semua halaman seller', (tester) async {
    await outputDir.create(recursive: true);
    await TokenStorageService().clear();
    await tester.binding.setSurfaceSize(const Size(412, 915));

    await tester.pumpWidget(
      RepaintBoundary(key: boundaryKey, child: const ProviderScope(child: ShopySellerApp())),
    );

    await pumpFor(tester, const Duration(seconds: 1));
    await shoot(tester, '01_splash');

    await pumpFor(tester, const Duration(seconds: 3));
    await shoot(tester, '02_login');

    const email = String.fromEnvironment('SELLER_EMAIL', defaultValue: 'f9seller-1786764853@shopy.com');
    const password = String.fromEnvironment('SELLER_PASSWORD', defaultValue: 'Password123!');
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await pumpFor(tester, const Duration(seconds: 8));
    await shoot(tester, '03_beranda_dashboard');

    await tapTab(tester, 'Produk');
    await shoot(tester, '04_produk_list');

    await tapTab(tester, 'Pesanan');
    await shoot(tester, '05_pesanan_list');

    await tapTab(tester, 'Chat');
    await shoot(tester, '06_chat_list');

    await tapTab(tester, 'Toko');
    await shoot(tester, '07_profil_toko');

    await openStoreMenu(tester, 'Keuangan & Pencairan', '08_keuangan');
    await openStoreMenu(tester, 'Statistik Penjualan', '09_statistik');
    await openStoreMenu(tester, 'Promo & Voucher', '10_promo_voucher');
    await openStoreMenu(tester, 'Ulasan Produk', '11_ulasan');
    await openStoreMenu(tester, 'Notifikasi', '12_notifikasi');
    await openStoreMenu(tester, 'Rekening Bank', '13_rekening_bank');
    await openStoreMenu(tester, 'Alamat & Pengiriman', '14_alamat');
    await openStoreMenu(tester, 'Edit Profil Toko', '15_edit_profil');

    // Logout dulu supaya alur keluar akun ikut terverifikasi.
    final logout = find.text('Keluar Akun');
    await tester.scrollUntilVisible(logout, 200, scrollable: find.byType(Scrollable).last);
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(logout);
    await pumpFor(tester, const Duration(seconds: 3));
    await shoot(tester, '16_setelah_logout');

    // ⚠️ Diketahui: setelah blok ini, teardown Flutter mengembalikan ukuran
    // surface dan memicu satu layout pass terakhir yang melempar "RenderFlex
    // overflowed by 26 pixels". Sudah diselidiki dan BUKAN cacat halaman:
    // ke-16 screenshot render bersih di 412×915 maupun 360×800, dan Flutter
    // sendiri tidak bisa menunjuk widget-nya karena tree sudah dibongkar
    // (error "deactivated widget ancestor" yang menyertainya cuma efek samping
    // saat Flutter mencoba mendeskripsikan error pertama). Akibatnya test ini
    // selalu dilaporkan merah walau semua langkah dan screenshot-nya sukses —
    // yang dipakai adalah PNG di , bukan status hijau/merahnya.
  });
}
