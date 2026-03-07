import 'package:flutter_test/flutter_test.dart';
import 'package:aipray/main.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const AiprayApp());
    expect(find.text('Aipray'), findsOneWidget);
  });
}
