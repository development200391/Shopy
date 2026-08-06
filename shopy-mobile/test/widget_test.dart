import 'package:flutter_test/flutter_test.dart';

import 'package:shopy_mobile/main.dart';

void main() {
  testWidgets('ShopyApp renders home page with app name', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShopyApp());

    expect(find.text('Shopy'), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);
  });
}
