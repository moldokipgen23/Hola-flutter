import 'package:flutter_test/flutter_test.dart';
import 'package:eiho_one/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const EihoOneApp());
    expect(find.text('Eiho One'), findsOneWidget);
  });
}
