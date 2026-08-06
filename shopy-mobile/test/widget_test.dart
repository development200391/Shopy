import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shopy_mobile/main.dart';

void main() {
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  testWidgets('ShopyApp shows splash then navigates to Login screen', (
    WidgetTester tester,
  ) async {
    // flutter_secure_storage butuh platform channel yang tidak tersedia di widget
    // test — mock supaya AuthNotifier.bootstrap() selesai normal (dianggap belum login).
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      (call) async => null,
    );

    await tester.pumpWidget(const ProviderScope(child: ShopyApp()));
    await tester.pump();

    expect(find.text('Shopy'), findsOneWidget);
    expect(find.text('Belanja praktis, kapan saja'), findsOneWidget);

    // Lewati durasi minimum splash + bootstrap, lalu satu frame tambahan supaya
    // route baru (LoginScreen) selesai ter-build setelah pushReplacement.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();

    expect(find.text('Masuk'), findsWidgets);
  });
}
