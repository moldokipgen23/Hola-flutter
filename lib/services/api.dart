import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class ApiClient {
  static const String baseUrl = AppConfig.apiBaseUrl;
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  String? _token;
  http.Client client;
  static const Duration _timeout = Duration(seconds: 30);

  ApiClient({http.Client? httpClient}) : client = httpClient ?? http.Client();

  Future<Map<String, String>> get headers async {
    if (_token == null) {
      try {
        _token = await _storage
            .read(key: _tokenKey)
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        _token = null;
      }
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<void> setToken(String? token) async {
    _token = token;
    try {
      if (token != null) {
        await _storage
            .write(key: _tokenKey, value: token)
            .timeout(const Duration(seconds: 3));
      } else {
        await _storage
            .delete(key: _tokenKey)
            .timeout(const Duration(seconds: 3));
      }
    } catch (_) {}
  }

  Future<bool> hasToken() async {
    try {
      final token = await _storage
          .read(key: _tokenKey)
          .timeout(const Duration(seconds: 3));
      return token != null;
    } catch (_) {
      return false;
    }
  }

  /// Convert a possibly-relative image path (e.g. "storage/photos/x.jpg")
  /// into an absolute URL using the backend origin.
  static String imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '${AppConfig.storageBaseUrl}/$clean';
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParams);
    final response = await client
        .get(uri, headers: await headers)
        .timeout(_timeout);
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: await headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await client
        .put(
          Uri.parse('$baseUrl$path'),
          headers: await headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await client
        .delete(Uri.parse('$baseUrl$path'), headers: await headers)
        .timeout(_timeout);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      _token = null;
      _storage.delete(key: _tokenKey);
      throw Exception('Session expired. Please login again.');
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {};
      }
      throw Exception('Server error (${response.statusCode})');
    }

    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      }
      final message = body is Map
          ? (body['message']?.toString() ?? 'Something went wrong')
          : 'Something went wrong';
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to parse server response');
    }
  }
}

final api = ApiClient();
