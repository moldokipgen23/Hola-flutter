import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eiho_one/features/book/book_screen.dart';

import '../../helpers/test_api_mock.dart';

void main() {
  setUp(() => TestApiClient.install());
  tearDown(() => TestApiClient.restore());

  group('BookScreen', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BookScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(BookScreen), findsOneWidget);
    });

    testWidgets('displays header with title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BookScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Book'), findsOneWidget);
      expect(find.text('Appointments, rooms and services'), findsOneWidget);
    });

    testWidgets('shows what do you need header', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BookScreen()));
      await tester.pumpAndSettle();
      expect(find.text('What do you need?'), findsOneWidget);
    });

    testWidgets('renders in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.light(), home: const BookScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BookScreen), findsOneWidget);
    });

    testWidgets('renders in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: const BookScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BookScreen), findsOneWidget);
    });
  });
}
