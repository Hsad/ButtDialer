// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:phone_roulette/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PhoneRouletteApp());

    // Verify app shows initial UI
    expect(find.text('Spin'), findsWidgets);
  });
}
