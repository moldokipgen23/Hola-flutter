import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eiho_one/features/discover/discover_screen.dart';

import '../../helpers/test_api_mock.dart';

void main() {
  setUp(() => TestApiClient.install());
  tearDown(() => TestApiClient.restore());

  group('DiscoverScreen', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DiscoverScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(DiscoverScreen), findsOneWidget);
    });

    testWidgets('displays header with title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DiscoverScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Businesses, people and places'), findsOneWidget);
    });

    testWidgets('shows search bar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DiscoverScreen()));
      await tester.pumpAndSettle();
      expect(
        find.text('Search businesses, places, services...'),
        findsOneWidget,
      );
    });

    testWidgets('shows quick discover header', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DiscoverScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Quick discover'), findsOneWidget);
    });

    testWidgets('renders in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.light(), home: const DiscoverScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DiscoverScreen), findsOneWidget);
    });

    testWidgets('renders in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: const DiscoverScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DiscoverScreen), findsOneWidget);
    });
  });
}
