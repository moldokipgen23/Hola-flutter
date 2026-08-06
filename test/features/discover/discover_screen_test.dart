import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eiho_one/features/discover/discover_screen.dart';

import '../../helpers/test_api_mock.dart';

Map<String, dynamic> _bookableJson({
  required int id,
  required String name,
  required String slug,
}) {
  return {
    'id': id,
    'name': name,
    'slug': slug,
    'photos': <String>[],
    'average_rating': 4.2,
    'review_count': 10,
    'distance': '0.8',
    'category': {
      'id': 8,
      'name': 'Beauty & Wellness',
      'slug': 'beauty-wellness',
      'icon': '💇',
    },
    'working_hours': <String, dynamic>{},
    'primary_action': {'type': 'book', 'label': 'Book Now'},
    'booking': {
      'can_book_online': true,
      'book_cta': 'in_app',
      'ready_experiences': ['appointment'],
      'primary_experience': 'appointment',
      'contact': {'phone': '1111111111', 'whatsapp': '1111111111'},
    },
  };
}

const _citiesPayload =
    '{"cities":[{"id":1,"name":"Lamka (Churachandpur)","slug":"lamka","state":"Manipur"},{"id":2,"name":"Delhi","slug":"delhi","state":"Delhi"}]}';

const _categoriesPayload =
    '{"categories":[{"id":8,"name":"Beauty & Wellness","slug":"beauty-wellness","icon":"💇","businesses_count":2}]}';

String _businessesPayload() {
  return jsonEncode({
    'businesses': {
      'data': [_bookableJson(id: 1, name: 'Salon A', slug: 'salon-a')],
    },
  });
}

String _responder(String path) {
  switch (path) {
    case '/cities':
      return _citiesPayload;
    case '/categories':
      return _categoriesPayload;
    case '/businesses':
      return _businessesPayload();
    default:
      return '{"data":[]}';
  }
}

void main() {
  group('DiscoverScreen', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      TestApiClient.install();
      addTearDown(TestApiClient.restore);
      await tester.pumpWidget(const MaterialApp(home: DiscoverScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(DiscoverScreen), findsOneWidget);
    });

    testWidgets('shows greeting and city name', (WidgetTester tester) async {
      TestApiClient.installWith(_responder);
      addTearDown(TestApiClient.restore);
      await tester.pumpWidget(const MaterialApp(home: DiscoverScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Lamka'), findsWidgets);
    });

    testWidgets('shows category rail', (WidgetTester tester) async {
      TestApiClient.installWith(_responder);
      addTearDown(TestApiClient.restore);
      await tester.pumpWidget(const MaterialApp(home: DiscoverScreen()));
      await tester.pumpAndSettle();
      expect(find.text('All'), findsWidgets);
    });

    testWidgets('shows trending section with bookable business', (
      WidgetTester tester,
    ) async {
      TestApiClient.installWith(_responder);
      addTearDown(TestApiClient.restore);
      await tester.pumpWidget(const MaterialApp(home: DiscoverScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Salon A'), findsWidgets);
      expect(find.text('Book'), findsWidgets);
    });

    testWidgets('shows empty state gracefully when no businesses', (
      WidgetTester tester,
    ) async {
      TestApiClient.install();
      addTearDown(TestApiClient.restore);
      await tester.pumpWidget(const MaterialApp(home: DiscoverScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(DiscoverScreen), findsOneWidget);
    });
  });
}
