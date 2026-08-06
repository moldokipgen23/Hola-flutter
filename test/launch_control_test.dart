import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eiho_one/main.dart';
import 'package:eiho_one/models/launch_config.dart';
import 'package:eiho_one/services/launch_control_service.dart';

import 'helpers/test_api_mock.dart';

void main() {
  test(
    'order routes require the orders module while browsing remains open',
    () {
      final config = LaunchConfig(
        worlds: const {'shop': true, 'book': true, 'discover': true},
        modules: const {
          'catalog': true,
          'orders': false,
          'inventory': false,
          'bookings': true,
          'transport': false,
          'turf': true,
        },
        experiences: const {
          'directory': true,
          'retail': true,
          'restaurant': true,
          'appointment': true,
          'stay': true,
          'turf': true,
          'taxi': false,
          'shared_transport': false,
          'vehicle_rental': false,
          'goods_transport': false,
          'seat_event': false,
        },
        onlinePayments: false,
      );
      final service = LaunchControlService.instance;
      service.setConfigForTesting(config);

      expect(service.allowsRoute('/retail/storefront'), isTrue);
      expect(service.allowsRoute('/retail/checkout'), isFalse);
      expect(service.allowsRoute('/restaurant/checkout'), isFalse);
    },
  );

  testWidgets('disabled worlds are removed from the main navigation', (
    tester,
  ) async {
    TestApiClient.install();
    addTearDown(TestApiClient.restore);
    final config = LaunchConfig(
      worlds: const {
        'shop': false,
        'ride': false,
        'book': false,
        'discover': true,
      },
      modules: LaunchConfig.defaults().modules,
      experiences: LaunchConfig.defaults().experiences,
      onlinePayments: false,
    );

    await tester.pumpWidget(
      MaterialApp(home: MainScreen(launchConfig: config)),
    );

    expect(find.text('Discover'), findsWidgets);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Shop'), findsNothing);
    expect(find.text('Ride'), findsNothing);
    expect(find.text('Book'), findsNothing);

    await tester.pumpAndSettle();
  });
}
