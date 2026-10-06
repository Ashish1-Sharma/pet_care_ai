import 'package:flutter_test/flutter_test.dart';
import 'package:ai_pet_care/main.dart';

void main() {
  testWidgets('App boots up and displays Splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the Splash screen title is displayed.
    expect(find.text('Pet Scan AI'), findsOneWidget);
    expect(find.text('Instant AI pet health scanner'), findsOneWidget);

    // Let the splash screen timer and animation finish
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
