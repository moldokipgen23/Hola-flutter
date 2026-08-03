import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eiho_one/features/ride/ride_screen.dart';

import '../../helpers/test_api_mock.dart';

void main() {
  setUp(() => TestApiClient.install());
  tearDown(() => TestApiClient.restore());

  group('RideScreen', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RideScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(RideScreen), findsOneWidget);
    });

    testWidgets('displays header with title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RideScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Ride'), findsOneWidget);
      expect(find.text('Local transport in Churachandpur'), findsOneWidget);
    });

    testWidgets('shows route box', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RideScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Where are you going?'), findsOneWidget);
      expect(find.text('Current location'), findsOneWidget);
      expect(find.text('Enter destination'), findsOneWidget);
    });

    testWidgets('shows Choose a service header', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RideScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Choose a service'), findsOneWidget);
    });

    testWidgets('renders in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.light(), home: const RideScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RideScreen), findsOneWidget);
    });

    testWidgets('renders in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: const RideScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RideScreen), findsOneWidget);
    });
  });
}
