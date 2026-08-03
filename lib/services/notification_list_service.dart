import 'api.dart';

class NotificationListService {
  static Future<List<Map<String, dynamic>>> list({int page = 1}) async {
    try {
      final params = <String, String>{'page': page.toString()};

      final response = await api.get('/notifications', queryParams: params);
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

  static Future<void> markRead(int id) async {
    try {
      await api.post('/notifications/$id/read', body: {});
    } catch (_) {}
  }

  static Future<void> markAllRead() async {
    try {
      await api.post('/notifications/read-all', body: {});
    } catch (_) {}
  }
}
