import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shopy_seller/providers/auth_provider.dart';
import 'package:shopy_seller/providers/auth_state.dart';
import 'package:shopy_seller/main.dart';

/// Auth sudah unauthenticated dari awal, jadi test tidak perlu mock
/// `flutter_secure_storage` (yang butuh platform channel) lewat [AuthNotifier.bootstrap]
/// — pola sama seperti `shopy-mobile/test/home_screen_test.dart`.
class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState.unauthenticated();

  // SplashScreen selalu memanggil bootstrap() — no-op di sini karena state awal
  // sudah pasti (lihat build()), supaya tidak ikut menyentuh secure storage asli.
  @override
  Future<void> bootstrap() async {}
}

void main() {
  testWidgets('ShopySellerApp mengarahkan user unauthenticated ke LoginScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_FakeAuthNotifier.new)],
        child: const ShopySellerApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Shopy Seller'), findsOneWidget);

    // Splash tetap nunggu delay 1400ms sebelum navigasi walau status auth sudah pasti.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // "Masuk" muncul 2x di LoginScreen (judul & tombol submit) — cukup pastikan ada.
    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Masuk untuk kelola toko Shopy kamu'), findsOneWidget);
  });
}
