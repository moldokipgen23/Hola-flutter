import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';

class PaymentService {
  static Future<bool> pay({
    required BuildContext context,
    required double amount,
    required String type,
    required int referenceId,
    required String gateway,
    int? businessId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (businessId != null) {
        queryParams['business_id'] = businessId.toString();
      }
      final config = await api.get(
        '/payments/config',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      if (!context.mounted) return false;

      if (gateway == 'razorpay') {
        return _payRazorpay(context, config, amount, type, referenceId);
      } else if (gateway == 'cashfree') {
        return _payCashfree(context, config, amount, type, referenceId);
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment error: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
          ),
        );
      }
      return false;
    }
  }

  static Future<bool> _payRazorpay(
    BuildContext context,
    Map<String, dynamic> config,
    double amount,
    String type,
    int referenceId,
  ) async {
    final razorpayConfig = config['razorpay'] as Map<String, dynamic>?;
    final keyId = razorpayConfig?['key_id'] as String?;
    if (keyId == null || keyId.contains('test_XXXXX')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Razorpay not configured. Try another method.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    final orderRes = await api.post(
      '/payments/create-order',
      body: {
        'amount': amount,
        'currency': 'INR',
        'type': type,
        'reference_id': referenceId,
        'gateway': 'razorpay',
      },
    );

    final razorpayOrderId = orderRes['id'] as String;
    final orderAmount = orderRes['amount'] as int;
    final completer = Completer<bool>();

    final razorpay = Razorpay();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) async {
      try {
        await api.post(
          '/payments/verify',
          body: {
            'gateway': 'razorpay',
            'razorpay_order_id': response['razorpay_order_id'],
            'razorpay_payment_id': response['razorpay_payment_id'],
            'razorpay_signature': response['razorpay_signature'],
            'type': type,
            'reference_id': referenceId,
          },
        );
      } catch (_) {}
      completer.complete(true);
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      completer.complete(false);
    });

    razorpay.open({
      'key': keyId,
      'amount': orderAmount,
      'order_id': razorpayOrderId,
      'name': 'Eiho One',
      'description':
          '${type[0].toUpperCase()}${type.substring(1)} #$referenceId',
      'theme': {'color': '#3B82F6'},
    });

    return completer.future;
  }

  static Future<bool> _payCashfree(
    BuildContext context,
    Map<String, dynamic> config,
    double amount,
    String type,
    int referenceId,
  ) async {
    final cashfreeConfig = config['cashfree'] as Map<String, dynamic>?;
    final appId = cashfreeConfig?['app_id'] as String?;
    final env = cashfreeConfig?['env'] as String? ?? 'TEST';

    if (appId == null || appId.contains('test_XXXXX')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cashfree not configured. Try another method.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    final orderRes = await api.post(
      '/payments/create-order',
      body: {
        'amount': amount,
        'currency': 'INR',
        'type': type,
        'reference_id': referenceId,
        'gateway': 'cashfree',
      },
    );

    final paymentSessionId = orderRes['payment_session_id'] as String?;
    if (paymentSessionId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create Cashfree session.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    // Open Cashfree checkout in browser
    final baseUrl = env == 'PRODUCTION'
        ? 'https://pay.cashfree.com'
        : 'https://pay.cashfree.com';
    final checkoutUrl =
        '$baseUrl/checkout?appId=$appId&paymentSessionId=$paymentSessionId';

    final uri = Uri.parse(checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!context.mounted) return false;

    // For Cashfree web checkout, we mark as success and let webhook handle verification
    // The merchant will see the payment status update via webhook
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cashfree checkout opened in browser. Complete payment there.',
        ),
        backgroundColor: Colors.blue,
      ),
    );

    return true;
  }
}
