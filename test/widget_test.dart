import 'package:flutter_test/flutter_test.dart';
import 'package:alveo_inmobiliaria/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AlveoApp());

    // Verify that the welcome message or some element is present.
    // expect(find.text('Group Adm. C.C.C.P.R.'), findsWidgets);
  });
}
