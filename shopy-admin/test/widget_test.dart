import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shopy_admin/providers/auth_provider.dart';
import 'package:shopy_admin/providers/auth_state.dart';
import 'package:shopy_admin/main.dart';

/// Auth sudah unauthenticated dari awal, jadi test tidak perlu mock
/// `flutter_secure_storage` (yang butuh platform channel) lewat [AuthNotifier.bootstrap]
/// — pola sama seperti `shopy-seller/test/widget_test.dart`.
class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState.unauthenticated();

  @override
  Future<void> bootstrap() async {}
}

void main() {
  testWidgets('ShopyAdminApp mengarahkan user unauthenticated ke LoginScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_FakeAuthNotifier.new)],
        child: const ShopyAdminApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Shopy Admin'), findsOneWidget);

    // Splash tetap nunggu delay 1400ms sebelum navigasi walau status auth sudah pasti.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Khusus akun admin — akun lain akan ditolak'), findsOneWidget);
  });
}
