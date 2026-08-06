import 'api.dart';
import '../models/models.dart';

class CityService {
  static List<CityRef>? _cache;

  static Future<List<CityRef>> getCities({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) return _cache!;
    try {
      final response = await api.get('/cities');
      List items = [];
      if (response is Map<String, dynamic>) {
        items = response['cities'] as List? ?? response['data'] as List? ?? [];
      } else if (response is List) {
        items = response;
      }
      final cities = items
          .map((c) =>
              c is Map<String, dynamic> ? CityRef.fromJson(c) : null)
          .whereType<CityRef>()
          .toList();
      _cache = cities;
      return cities;
    } catch (_) {
      return [];
    }
  }

  static void clearCache() {
    _cache = null;
  }
}

/// A category shown in the Discover left rail.
class DiscoverCategory {
  final String slug;
  final String label;
  final String emoji;
  const DiscoverCategory(this.slug, this.label, this.emoji);
}

/// Stable top-level categories surfaced in the Discover left rail.
/// The server list (when it returns) is preferred; this is the offline fallback.
const List<DiscoverCategory> kDiscoverCategories = [
  DiscoverCategory('all', 'All', '✨'),
  DiscoverCategory('food-restaurants', 'Food', '🍽️'),
  DiscoverCategory('hotels-lodges', 'Hotels', '🏨'),
  DiscoverCategory('healthcare', 'Health', '🏥'),
  DiscoverCategory('beauty-wellness', 'Beauty', '💇'),
  DiscoverCategory('education', 'Learning', '📚'),
  DiscoverCategory('sports-fitness', 'Turf', '⚽'),
  DiscoverCategory('shopping-retail', 'Shops', '🛍️'),
  DiscoverCategory('professional-services', 'Services', '💼'),
];