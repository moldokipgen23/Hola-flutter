import 'api.dart';
import '../models/vehicle.dart';

class TripService {
  static Future<Map<String, dynamic>> create({
    required String businessSlug,
    int? vehicleId,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required String pickupLocation,
    required String dropLocation,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    double? distanceKm,
    double? fare,
    int seatsRequired = 1,
    String? tripDate,
    String? tripTime,
    String requestType = 'ride',
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'pickup_location': pickupLocation,
        'drop_location': dropLocation,
        'seats_required': seatsRequired,
        'request_type': requestType,
      };
      if (vehicleId != null) body['vehicle_id'] = vehicleId;
      if (customerEmail != null) body['customer_email'] = customerEmail;
      if (pickupLat != null) body['pickup_lat'] = pickupLat;
      if (pickupLng != null) body['pickup_lng'] = pickupLng;
      if (dropLat != null) body['drop_lat'] = dropLat;
      if (dropLng != null) body['drop_lng'] = dropLng;
      if (distanceKm != null) body['distance_km'] = distanceKm;
      if (fare != null) body['fare'] = fare;
      if (tripDate != null) body['trip_date'] = tripDate;
      if (tripTime != null) body['trip_time'] = tripTime;
      if (notes != null) body['notes'] = notes;

      final response = await api.post(
        '/businesses/$businessSlug/trips',
        body: body,
      );
      if (response is Map<String, dynamic>) return response;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> estimate({
    required String businessSlug,
    int? vehicleId,
    required String pickupLocation,
    required String dropLocation,
    double? distanceKm,
  }) async {
    try {
      final body = <String, dynamic>{
        'pickup_location': pickupLocation,
        'drop_location': dropLocation,
      };
      if (vehicleId != null) body['vehicle_id'] = vehicleId;
      if (distanceKm != null) body['distance_km'] = distanceKm;

      final response = await api.post(
        '/businesses/$businessSlug/trips/estimate',
        body: body,
      );
      if (response is Map<String, dynamic>) return response;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<List<Trip>> myTrips({String? status, int page = 1}) async {
    try {
      final params = <String, String>{'page': page.toString()};
      if (status != null) params['status'] = status;

      final response = await api.get('/my-trips', queryParams: params);
      if (response == null) return [];
      if (response is List) {
        return response
            .map<Trip>((e) => Trip.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) {
          return data
              .map<Trip>((e) => Trip.fromJson(e as Map<String, dynamic>))
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
        '/my-trips/$id/cancel',
        body: body.isNotEmpty ? body : null,
      );
    } catch (_) {}
  }
}
