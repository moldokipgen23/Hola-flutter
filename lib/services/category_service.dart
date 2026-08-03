import 'api.dart';
import '../models/models.dart';

class CategoryService {
  static List<Category>? _cache;

  static Future<List<Category>> getCategories({String? worldSlug}) async {
    if (_cache != null && worldSlug == null) return _cache!;

    try {
      final response = worldSlug != null
          ? await api.get('/worlds/$worldSlug/categories')
          : await api.get('/categories');

      List items;
      if (response is Map<String, dynamic>) {
        items =
            response['categories'] as List? ?? response['data'] as List? ?? [];
      } else if (response is List) {
        items = response;
      } else {
        return _getFallbackCategories(worldSlug);
      }

      final categories = items
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .where((c) => c.isActive)
          .toList();

      if (worldSlug == null) _cache = categories;
      return categories;
    } catch (_) {
      return _getFallbackCategories(worldSlug);
    }
  }

  static Future<List<Category>> getCategoriesForWorld(String worldSlug) async {
    return getCategories(worldSlug: worldSlug);
  }

  static void clearCache() {
    _cache = null;
  }

  static List<Category> _getFallbackCategories(String? worldSlug) {
    final all = [
      Category(
        id: 1,
        name: 'Food & Restaurants',
        slug: 'food-restaurants',
        icon: '🍽️',
        moduleType: 'ordering',
      ),
      Category(
        id: 2,
        name: 'Hotels & Lodges',
        slug: 'hotels-lodges',
        icon: '🏨',
        moduleType: 'booking',
      ),
      Category(
        id: 3,
        name: 'Healthcare',
        slug: 'healthcare',
        icon: '🏥',
        moduleType: 'booking',
      ),
      Category(
        id: 4,
        name: 'Education',
        slug: 'education',
        icon: '📚',
        moduleType: 'booking',
      ),
      Category(
        id: 5,
        name: 'Shopping & Retail',
        slug: 'shopping-retail',
        icon: '🛍️',
        moduleType: 'ordering',
      ),
      Category(
        id: 6,
        name: 'Electronics & Tech',
        slug: 'electronics-tech',
        icon: '💻',
        moduleType: 'ordering',
      ),
      Category(
        id: 7,
        name: 'Automobiles',
        slug: 'automobiles',
        icon: '🚗',
        moduleType: 'booking',
      ),
      Category(
        id: 8,
        name: 'Beauty & Wellness',
        slug: 'beauty-wellness',
        icon: '💇',
        moduleType: 'booking',
      ),
      Category(
        id: 9,
        name: 'Professional Services',
        slug: 'professional-services',
        icon: '💼',
        moduleType: 'directory',
      ),
      Category(
        id: 10,
        name: 'Sports & Fitness',
        slug: 'sports-fitness',
        icon: '🏋️',
        moduleType: 'booking',
      ),
      Category(
        id: 11,
        name: 'Transport',
        slug: 'transport',
        icon: '🚕',
        moduleType: 'directory',
      ),
      Category(
        id: 12,
        name: 'Government & Public Services',
        slug: 'government-public-services',
        icon: '🏛️',
        moduleType: 'directory',
      ),
      Category(
        id: 13,
        name: 'Religious & Community Places',
        slug: 'religious-community-places',
        icon: '⛪',
        moduleType: 'directory',
      ),
      Category(
        id: 14,
        name: 'Tourism & Attractions',
        slug: 'tourism-attractions',
        icon: '📍',
        moduleType: 'directory',
      ),
      Category(
        id: 15,
        name: 'Home & Local Services',
        slug: 'home-local-services',
        icon: '🔧',
        moduleType: 'booking',
      ),
    ];

    if (worldSlug == null) return all;
    return all;
  }
}
