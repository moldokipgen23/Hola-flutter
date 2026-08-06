import 'package:flutter_test/flutter_test.dart';
import 'package:eiho_one/features/search/search_screen.dart';

void main() {
  group('SearchScreen.parseSearchResults', () {
    test('parses businesses from /search sections payload', () {
      final result = {
        'query': 'turf',
        'total': 1,
        'sections': [
          {
            'type': 'categories',
            'items': [
              {
                'id': 1,
                'name': 'Sports',
                'slug': 'sports',
              },
            ],
          },
          {
            'type': 'businesses',
            'items': [
              {
                'id': 317,
                'name': 'HUB Turf Ground',
                'slug': 'hub-turf-ground',
                'address': 'Church Rd, Zion Veng',
                'locality': 'Churachandpur',
                'photos': ['storage/businesses/hub-turf-ground_ZAyB9r.jpg'],
                'average_rating': 4,
                'category': {
                  'id': 15,
                  'name': 'Establishment',
                  'slug': 'establishment',
                  'icon': '📂',
                },
              },
            ],
          },
        ],
      };

      final results = SearchScreen.parseSearchResults(result);

      expect(results, hasLength(1));
      expect(results.first.name, 'HUB Turf Ground');
      expect(results.first.slug, 'hub-turf-ground');
      expect(results.first.photos, [
        'storage/businesses/hub-turf-ground_ZAyB9r.jpg',
      ]);
      expect(results.first.category?.name, 'Establishment');
    });

    test('skips malformed items instead of failing the whole search', () {
      final result = {
        'sections': [
          {
            'type': 'businesses',
            'items': [
              'not-a-map',
              {'id': 1, 'name': 'OK Biz', 'slug': 'ok-biz'},
              null,
            ],
          },
        ],
      };

      final results = SearchScreen.parseSearchResults(result);

      expect(results, hasLength(1));
      expect(results.first.name, 'OK Biz');
    });

    test('falls back to legacy top-level businesses array', () {
      final result = {
        'businesses': [
          {'id': 1, 'name': 'Legacy Biz', 'slug': 'legacy-biz'},
        ],
      };

      final results = SearchScreen.parseSearchResults(result);

      expect(results, hasLength(1));
      expect(results.first.name, 'Legacy Biz');
    });

    test('returns empty list for unknown payloads', () {
      expect(SearchScreen.parseSearchResults(null), isEmpty);
      expect(SearchScreen.parseSearchResults('nope'), isEmpty);
      expect(SearchScreen.parseSearchResults({'nope': true}), isEmpty);
    });
  });
}
