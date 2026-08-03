import 'api.dart';
import '../models/models.dart';

class SearchService {
  static Future<Map<String, dynamic>> search(
    String query, {
    String? type,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'q': query, 'page': page.toString()};
      if (type != null) params['type'] = type;

      final response = await api.get('/search', queryParams: params);
      if (response is Map<String, dynamic>) return response;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<List<String>> suggestions(String query) async {
    try {
      final params = <String, String>{'q': query};
      final response = await api.get(
        '/search/suggestions',
        queryParams: params,
      );

      if (response is Map<String, dynamic>) {
        final suggestionsList = response['suggestions'];
        if (suggestionsList is List) {
          return suggestionsList.map((e) => e.toString()).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Business>> instantSearch(
    String query, {
    String? experience,
  }) async {
    try {
      final params = <String, String>{'q': query};
      if (experience != null) params['experience'] = experience;

      final response = await api.get('/instant-search', queryParams: params);
      if (response is Map<String, dynamic>) {
        final results = response['results'];
        if (results is List) {
          return results
              .map((e) => Business.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
