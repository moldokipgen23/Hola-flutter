import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eiho_one/main.dart';
import 'package:eiho_one/models/launch_config.dart';
import 'package:eiho_one/services/launch_control_service.dart';

void main() {
  test(
    'order routes require the orders module while browsing remains open',
    () {
      final defaults = LaunchConfig.defaults();
      final config = LaunchConfig(
        worlds: defaults.worlds,
        modules: {...defaults.modules, 'orders': false},
        experiences: defaults.experiences,
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
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Shop'), findsNothing);
    expect(find.text('Ride'), findsNothing);
    expect(find.text('Book'), findsNothing);

    await tester.pump(const Duration(seconds: 4));
  });
}
