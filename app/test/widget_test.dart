import 'package:flutter_test/flutter_test.dart';
import 'package:aiksetra_app/main.dart';

void main() {
  testWidgets('AikSetra App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AikSetraApp());
    expect(find.text('AikSetra'), findsWidgets);
  });
}
