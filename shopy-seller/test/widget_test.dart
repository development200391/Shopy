import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shopy_seller/main.dart';

void main() {
  testWidgets('ShopySellerApp renders placeholder home', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShopySellerApp()));
    await tester.pump();

    expect(find.text('Shopy Seller'), findsOneWidget);
  });
}
