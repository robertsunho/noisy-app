import 'package:flutter_test/flutter_test.dart';

import 'package:noisy_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NoisyApp());
    expect(find.text('Noisy'), findsOneWidget);
  });
}
