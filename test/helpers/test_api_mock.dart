import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:eiho_one/services/api.dart';

class TestApiClient {
  static http.Client? _originalClient;

  static void install() {
    _originalClient = api.client;
    api.client = MockClient((request) async {
      return http.Response(
        '{"data":[]}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
  }

  static void restore() {
    if (_originalClient != null) {
      api.client = _originalClient!;
      _originalClient = null;
    }
  }
}
