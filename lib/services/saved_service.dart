import 'api.dart';

class SavedService {
  static Future<bool> toggle(int businessId) async {
    try {
      final response = await api.post(
        '/saved/toggle',
        body: {'business_id': businessId},
      );
      if (response is Map<String, dynamic>) {
        return response['is_saved'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> list({int page = 1}) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'per_page': '50',
      };

      final response = await api.get('/saved', queryParams: params);
      if (response == null) return [];
      if (response is List) {
        return response
            .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
            .toList();
      }
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) {
          return data
              .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
