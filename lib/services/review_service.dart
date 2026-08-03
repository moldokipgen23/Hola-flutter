import 'api.dart';
import '../models/models.dart';

class ReviewService {
  static Future<List<Review>> list(int businessId, {int page = 1}) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'per_page': '20',
      };

      final response = await api.get(
        '/businesses/$businessId/reviews',
        queryParams: params,
      );
      if (response == null) return [];
      if (response is List) {
        return response
            .map<Review>((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) {
          return data
              .map<Review>((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Review> create(
    int businessId, {
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await api.post(
        '/businesses/$businessId/reviews',
        body: {'rating': rating, 'comment': comment},
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is Map<String, dynamic>) return Review.fromJson(data);
        return Review.fromJson(response);
      }
      return Review(
        id: 0,
        userId: 0,
        businessId: businessId,
        rating: rating,
        comment: comment,
      );
    } catch (_) {
      return Review(
        id: 0,
        userId: 0,
        businessId: businessId,
        rating: rating,
        comment: comment,
      );
    }
  }
}
