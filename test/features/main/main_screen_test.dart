import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eiho_one/main.dart';

import '../../helpers/test_api_mock.dart';

void main() {
  setUp(() => TestApiClient.install());
  tearDown(() => TestApiClient.restore());

  group('MainScreen Navigation', () {
    testWidgets('renders the three bucket tabs plus account', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Shopping'), findsWidgets);
      expect(find.text('Ride'), findsNothing);
      expect(find.text('Booking'), findsWidgets);
      expect(find.text('Directory'), findsWidgets);
      expect(find.text('Account'), findsWidgets);
    });

    testWidgets('can switch between tabs', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Booking'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Directory'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();
    });

    testWidgets('Shopping tab shows ShopScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Delivering to'), findsOneWidget);
    });

    testWidgets('Booking tab shows BookScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Booking'));
      await tester.pumpAndSettle();

      expect(find.text('Booking'), findsWidgets);
    });

    testWidgets('Directory tab shows DiscoverScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Directory'));
      await tester.pumpAndSettle();

      expect(find.text('Directory'), findsWidgets);
    });

    testWidgets('Account tab shows ProfileScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsWidgets);
    });
  });
}
