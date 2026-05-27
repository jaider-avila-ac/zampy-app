import 'package:flutter_test/flutter_test.dart';
import 'package:zampy_app/main.dart';

void main() {
  testWidgets('ZampyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZampyApp());
  });
}
