import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/launch_config.dart';
import 'api.dart';

class LaunchControlService extends ChangeNotifier {
  LaunchControlService._();

  static final LaunchControlService instance = LaunchControlService._();
  static const _cacheKey = 'platform_launch_config_v1';

  LaunchConfig _config = LaunchConfig.defaults();
  LaunchConfig get config => _config;

  @visibleForTesting
  void setConfigForTesting(LaunchConfig config) {
    _config = config;
  }

  Future<void> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        _config = LaunchConfig.fromJson(
          Map<String, dynamic>.from(jsonDecode(cached) as Map),
        );
      }
    } catch (_) {
      // Safe launch defaults keep the current released experience available.
    }
  }

  Future<void> refresh() async {
    try {
      final response = await api.get('/platform/features');
      final data = Map<String, dynamic>.from(response['data'] as Map);
      _config = LaunchConfig.fromJson(data);
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(_config.toJson()));
    } catch (_) {
      // Offline users keep the last server-approved configuration.
    }
  }

  bool allowsRoute(String? route) {
    if (route == null) return true;
    if (route.startsWith('/retail/')) {
      final canBrowse =
          _config.world('shop') &&
          _config.module('catalog') &&
          _config.experience('retail');
      final orderRoute =
          route == '/retail/cart' ||
          route == '/retail/checkout' ||
          route == '/retail/order-confirmation' ||
          route == '/retail/order-status';
      return canBrowse && (!orderRoute || _config.module('orders'));
    }
    if (route.startsWith('/restaurant/')) {
      final canBrowse =
          _config.world('shop') &&
          _config.module('catalog') &&
          _config.experience('restaurant');
      final orderRoute =
          route == '/restaurant/cart' ||
          route == '/restaurant/checkout' ||
          route == '/restaurant/tracking';
      return canBrowse && (!orderRoute || _config.module('orders'));
    }
    if (route.startsWith('/appointment/')) {
      return _config.world('book') &&
          _config.module('bookings') &&
          _config.experience('appointment');
    }
    if (route.startsWith('/stay/')) {
      return _config.world('book') &&
          _config.module('bookings') &&
          _config.experience('stay');
    }
    if (route.startsWith('/turf/')) {
      return _config.world('book') &&
          _config.module('bookings') &&
          _config.module('turf') &&
          _config.experience('turf');
    }
    if (route.startsWith('/taxi/')) {
      return _config.world('ride') &&
          _config.module('transport') &&
          _config.experience('taxi');
    }
    if (route.startsWith('/transport/shared')) {
      return _config.world('ride') &&
          _config.module('transport') &&
          _config.experience('shared_transport');
    }
    if (route == '/transport/rental') {
      return _config.world('ride') &&
          _config.module('transport') &&
          _config.experience('vehicle_rental');
    }
    if (route == '/transport/goods') {
      return _config.world('ride') &&
          _config.module('transport') &&
          _config.experience('goods_transport');
    }
    if (route == '/my-orders') return _config.module('orders');
    if (route == '/my-bookings') return _config.module('bookings');
    if (route == '/my-trips') return _config.module('transport');
    return true;
  }
}
