import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eiho_one/main.dart';
import 'package:eiho_one/screens/splash_screen.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const EihoOneApp());
    // Splash shows the branded logo image on the brand gradient.
    expect(find.byType(Image), findsWidgets);
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
