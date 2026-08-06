import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:eiho_one/services/api.dart';
import 'package:eiho_one/services/city_service.dart';
import 'package:eiho_one/services/category_service.dart';

class TestApiClient {
  static http.Client? _originalClient;

  /// Channel used by flutter_secure_storage. In widget tests the platform
  /// side never answers, which would hang ApiClient's token read; mock it so
  /// reads/writes return instantly.
  static const _storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  static void _mockSecureStorage() {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
        .setMockMethodCallHandler(_storageChannel, (call) async => null);
  }

  static void _clearSecureStorage() {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
        .setMockMethodCallHandler(_storageChannel, null);
  }

  /// Existing behaviour: every request returns `{"data":[]}`.
  static void install() {
    installWith((path) => '{"data":[]}');
  }

  /// Install a mock that dispatches by request path.
  /// `responder` returns the raw response body for a given request path.
  static void installWith(String Function(String path) responder) {
    _mockSecureStorage();
    CityService.clearCache();
    CategoryService.clearCache();
    _originalClient = api.client;
    api.client = MockClient((request) async {
      final path = request.url.path.replaceFirst('/api', '');
      final body = responder(path);
      return http.Response(
        body,
        200,
        headers: {'content-type': 'application/json'},
      );
    });
  }

  static void restore() {
    _clearSecureStorage();
    if (_originalClient != null) {
      api.client = _originalClient!;
      _originalClient = null;
    }
  }
}