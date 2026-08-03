import 'api.dart';
import '../models/booking.dart';

class BookingService {
  static Future<Map<String, dynamic>> create({
    required String businessSlug,
    int? serviceId,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required String bookingDate,
    String? startTime,
    String? endTime,
    int? partySize,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'booking_date': bookingDate,
      };
      if (serviceId != null) body['service_id'] = serviceId;
      if (customerEmail != null) body['customer_email'] = customerEmail;
      if (startTime != null) body['start_time'] = startTime;
      if (endTime != null) body['end_time'] = endTime;
      if (partySize != null) body['party_size'] = partySize;
      if (notes != null) body['notes'] = notes;

      final response = await api.post(
        '/businesses/$businessSlug/bookings',
        body: body,
      );
      if (response is Map<String, dynamic>) return response;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<List<Booking>> myBookings({
    String? status,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'page': page.toString()};
      if (status != null) params['status'] = status;

      final response = await api.get('/my-bookings', queryParams: params);
      if (response == null) return [];
      if (response is List) {
        return response
            .map<Booking>((e) => Booking.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (response is Map<String, dynamic>) {
        final bookings = response['bookings'];
        if (bookings is List) {
          return bookings
              .map<Booking>((e) => Booking.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        final data = response['data'];
        if (data is List) {
          return data
              .map<Booking>((e) => Booking.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> cancel(int id, {String? reason}) async {
    try {
      final body = <String, dynamic>{};
      if (reason != null) body['reason'] = reason;

      await api.put(
        '/my-bookings/$id/cancel',
        body: body.isNotEmpty ? body : null,
      );
    } catch (_) {}
  }
}
