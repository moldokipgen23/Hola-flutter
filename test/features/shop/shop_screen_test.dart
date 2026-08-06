import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eiho_one/features/shop/shop_screen.dart';
import 'package:eiho_one/models/launch_config.dart';

import '../../helpers/test_api_mock.dart';

const _shopConfig = LaunchConfig(
  worlds: {'shop': true, 'book': true, 'discover': true},
  modules: {
    'catalog': true,
    'orders': true,
    'inventory': true,
    'bookings': true,
    'transport': true,
    'turf': true,
  },
  experiences: {
    'directory': true,
    'retail': true,
    'restaurant': true,
    'appointment': true,
    'stay': true,
    'turf': true,
    'taxi': true,
    'shared_transport': true,
    'vehicle_rental': true,
    'goods_transport': true,
    'seat_event': true,
  },
  onlinePayments: false,
);

void main() {
  setUp(() => TestApiClient.install());
  tearDown(() => TestApiClient.restore());

  group('ShopScreen', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ShopScreen(launchConfig: _shopConfig)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShopScreen), findsOneWidget);
    });

    testWidgets('displays location header', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ShopScreen(launchConfig: _shopConfig)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delivering to'), findsOneWidget);
      expect(find.text('Home ›'), findsOneWidget);
    });

    testWidgets('shows department switcher', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ShopScreen(launchConfig: _shopConfig)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shopping'), findsWidgets);
      expect(find.text('Grocery'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Medicine'), findsOneWidget);
    });

    testWidgets('departments are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ShopScreen(launchConfig: _shopConfig)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medicine').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grocery').first);
      await tester.pumpAndSettle();
    });

    testWidgets('shows search bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ShopScreen(launchConfig: _shopConfig)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Search fashion, electronics, gifts...'),
        findsOneWidget,
      );
    });

    testWidgets('renders in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const ShopScreen(launchConfig: _shopConfig),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShopScreen), findsOneWidget);
    });

    testWidgets('renders in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const ShopScreen(launchConfig: _shopConfig),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShopScreen), findsOneWidget);
    });
  });
}
