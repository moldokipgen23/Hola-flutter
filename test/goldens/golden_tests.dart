import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eiho_one/features/shop/shop_screen.dart';
import 'package:eiho_one/features/ride/ride_screen.dart';
import 'package:eiho_one/features/book/book_screen.dart';
import 'package:eiho_one/features/discover/discover_screen.dart';
import 'package:eiho_one/main.dart';

void main() {
  group('Golden tests - Light theme', () {
    testWidgets('ShopScreen light', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const ShopScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ShopScreen),
        matchesGoldenFile('goldens/shop_screen_light.png'),
      );
    });

    testWidgets('RideScreen light', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const RideScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(RideScreen),
        matchesGoldenFile('goldens/ride_screen_light.png'),
      );
    });

    testWidgets('BookScreen light', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const BookScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(BookScreen),
        matchesGoldenFile('goldens/book_screen_light.png'),
      );
    });

    testWidgets('DiscoverScreen light', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const DiscoverScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DiscoverScreen),
        matchesGoldenFile('goldens/discover_screen_light.png'),
      );
    });

    testWidgets('MainScreen navigation light', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const MainScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MainScreen),
        matchesGoldenFile('goldens/main_screen_light.png'),
      );
    });
  });

  group('Golden tests - Dark theme', () {
    testWidgets('ShopScreen dark', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const ShopScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ShopScreen),
        matchesGoldenFile('goldens/shop_screen_dark.png'),
      );
    });

    testWidgets('RideScreen dark', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const RideScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(RideScreen),
        matchesGoldenFile('goldens/ride_screen_dark.png'),
      );
    });

    testWidgets('DiscoverScreen dark', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const DiscoverScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(DiscoverScreen),
        matchesGoldenFile('goldens/discover_screen_dark.png'),
      );
    });
  });
}
