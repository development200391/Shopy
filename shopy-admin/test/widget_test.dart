import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shopy_admin/main.dart';

void main() {
  testWidgets('ShopyAdminApp shows placeholder home', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShopyAdminApp()));

    expect(find.text('Shopy Admin'), findsOneWidget);
  });
}
