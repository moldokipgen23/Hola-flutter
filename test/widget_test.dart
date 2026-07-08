import 'package:flutter_test/flutter_test.dart';
import 'package:hola/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const HolaApp());
    expect(find.text('Hola'), findsOneWidget);
  });
}
