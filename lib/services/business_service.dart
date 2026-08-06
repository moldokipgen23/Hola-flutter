import 'api.dart';
import '../models/models.dart';

class BusinessService {
  static List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = _extractItems(data);
    final result = <T>[];
    for (final e in items) {
      try {
        if (e is Map<String, dynamic>) {
          result.add(fromJson(e));
        }
      } catch (_) {
        // Skip a single malformed record instead of blanking the whole feed.
      }
    }
    return result;
  }

  static List<dynamic> _extractItems(dynamic data) {
    if (data == null) return const [];
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final businesses = data['businesses'];
      if (businesses is List) return businesses;
      if (businesses is Map<String, dynamic>) {
        final inner = businesses['data'];
        if (inner is List) return inner;
      }
      final items = data['data'];
      if (items is List) return items;
    }
    return const [];
  }

  static Future<List<Business>> list({
    String? experience,
    String? category,
    bool? featured,
    bool? popular,
    String? search,
    int? cityId,
    double? latitude,
    double? longitude,
    int? radius,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (experience != null) params['experience'] = experience;
      if (category != null) params['category'] = category;
      if (featured != null) params['featured'] = featured ? '1' : '0';
      if (popular != null) params['popular'] = popular ? '1' : '0';
      if (search != null) params['q'] = search;
      if (cityId != null) params['city_id'] = cityId.toString();
      if (latitude != null) params['latitude'] = latitude.toStringAsFixed(6);
      if (longitude != null) params['longitude'] = longitude.toStringAsFixed(6);
      if (radius != null) params['radius'] = radius.toString();

      final response = await api.get('/businesses', queryParams: params);
      return _parseList(response, Business.fromJson);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Business>> featured({String? experience}) async {
    try {
      final params = <String, String>{};
      if (experience != null) params['experience'] = experience;

      final response = await api.get(
        '/businesses/featured',
        queryParams: params.isNotEmpty ? params : null,
      );
      if (response is Map<String, dynamic>) {
        final businesses = response['businesses'];
        if (businesses is List) {
          return businesses
              .map((e) => Business.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return _parseList(response, Business.fromJson);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Business>> popular({String? experience}) async {
    try {
      final params = <String, String>{};
      if (experience != null) params['experience'] = experience;

      final response = await api.get(
        '/businesses/trending',
        queryParams: params.isNotEmpty ? params : null,
      );
      return _parseList(response, Business.fromJson);
    } catch (_) {
      return [];
    }
  }

  static Future<Business?> getBySlug(String slug) async {
    try {
      final response = await api.get('/businesses/$slug');
      if (response is Map<String, dynamic>) {
        final data = response['business'];
        if (data is Map<String, dynamic>) return Business.fromJson(data);
        return Business.fromJson(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Product>> products(
    String slug, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        'business_slug': slug,
      };

      final response = await api.get('/products', queryParams: params);
      if (response is Map<String, dynamic>) {
        final productsData = response['products'];
        if (productsData is Map<String, dynamic>) {
          final data = productsData['data'];
          if (data is List) {
            return data
                .map((e) => Product.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      }
      return _parseList(response, Product.fromJson);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Service>> services(String slug) async {
    try {
      final response = await api.get('/businesses/$slug/services');
      if (response is Map<String, dynamic>) {
        final servicesData = response['services'];
        if (servicesData is List) {
          return servicesData
              .map((e) => Service.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return _parseList(response, Service.fromJson);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Vehicle>> vehicles(String slug) async {
    try {
      final response = await api.get('/businesses/$slug/vehicles');
      if (response is Map<String, dynamic>) {
        final vehiclesData = response['vehicles'];
        if (vehiclesData is List) {
          return vehiclesData
              .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return _parseList(response, Vehicle.fromJson);
    } catch (_) {
      return [];
    }
  }

  static Future<List<TimeSlot>> slots(
    String slug, {
    int? serviceId,
    String? date,
  }) async {
    try {
      if (serviceId == null) return [];
      final params = <String, String>{};
      if (date != null) params['date'] = date;

      final response = await api.get(
        '/services/$serviceId/slots',
        queryParams: params.isNotEmpty ? params : null,
      );
      if (response is Map<String, dynamic>) {
        final slotsData = response['slots'];
        if (slotsData is List) {
          return slotsData
              .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return _parseList(response, TimeSlot.fromJson);
    } catch (_) {
      return [];
    }
  }
}
