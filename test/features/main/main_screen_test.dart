import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eiho_one/main.dart';
import 'package:eiho_one/features/discover/discover_screen.dart';
import 'package:eiho_one/features/shared/profile_screen.dart';
import 'package:eiho_one/features/shared/saved_screen.dart';
import 'package:eiho_one/features/search/search_screen.dart';

import '../../helpers/test_api_mock.dart';

void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> pumpMain(WidgetTester tester) async {
  usePhoneSurface(tester);
  await tester.pumpWidget(const MaterialApp(home: MainScreen()));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => TestApiClient.install());
  tearDown(() => TestApiClient.restore());

  group('MainScreen Navigation', () {
    testWidgets('renders the v3 shell tabs', (WidgetTester tester) async {
      await pumpMain(tester);

      expect(find.text('Discover'), findsWidgets);
      expect(find.text('Nearby'), findsWidgets);
      expect(find.text('Saved'), findsWidgets);
      expect(find.text('You'), findsWidgets);
    });

    testWidgets('can switch between tabs', (WidgetTester tester) async {
      await pumpMain(tester);

      await tester.tap(find.text('Nearby'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('You'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();
    });

    testWidgets('Discover tab shows DiscoverScreen', (
      WidgetTester tester,
    ) async {
      await pumpMain(tester);

      expect(find.byType(DiscoverScreen), findsOneWidget);
    });

    testWidgets('You tab shows ProfileScreen', (WidgetTester tester) async {
      await pumpMain(tester);

      await tester.tap(find.text('You'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('Saved tab shows SavedScreen', (WidgetTester tester) async {
      await pumpMain(tester);

      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      expect(find.byType(SavedScreen), findsOneWidget);
    });

    testWidgets('Nearby tab shows SearchScreen', (WidgetTester tester) async {
      await pumpMain(tester);

      await tester.tap(find.text('Nearby'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
    });
  });
}
