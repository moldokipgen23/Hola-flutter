import 'api.dart';
import '../models/order.dart';

class OrderService {
  static Future<Map<String, dynamic>> create({
    required String businessSlug,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? deliveryAddress,
    String deliveryMethod = 'delivery',
    String? notes,
    String? paymentMethod,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final body = <String, dynamic>{
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'delivery_method': deliveryMethod,
      };
      if (customerEmail != null) body['customer_email'] = customerEmail;
      if (deliveryAddress != null) body['delivery_address'] = deliveryAddress;
      if (notes != null) body['notes'] = notes;
      if (paymentMethod != null) body['payment_method'] = paymentMethod;
      if (items != null) body['items'] = items;

      final response = await api.post(
        '/businesses/$businessSlug/orders',
        body: body,
      );
      if (response is Map<String, dynamic>) return response;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<List<Order>> myOrders({String? status, int page = 1}) async {
    try {
      final params = <String, String>{'page': page.toString()};
      if (status != null) params['status'] = status;

      final response = await api.get('/my-orders', queryParams: params);
      if (response == null) return [];
      if (response is List) {
        return response
            .map<Order>((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (response is Map<String, dynamic>) {
        final orders = response['orders'];
        if (orders is List) {
          return orders
              .map<Order>((e) => Order.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        final data = response['data'];
        if (data is List) {
          return data
              .map<Order>((e) => Order.fromJson(e as Map<String, dynamic>))
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
        '/my-orders/$id/cancel',
        body: body.isNotEmpty ? body : null,
      );
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> reorder(int id) async {
    try {
      final response = await api.post('/my-orders/$id/reorder', body: {});
      if (response is Map<String, dynamic>) return response;
      return {};
    } catch (_) {
      return {};
    }
  }
}
