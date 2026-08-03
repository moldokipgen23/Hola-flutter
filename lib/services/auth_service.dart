import 'api.dart';

class AuthService {
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await api.post(
        '/auth/login',
        body: {'email': email, 'password': password},
      );
      if (response is Map<String, dynamic>) return response;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await api.post(
        '/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      if (response is Map<String, dynamic>) return response;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> logout() async {
    try {
      await api.post('/auth/logout', body: {});
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> profile() async {
    try {
      final response = await api.get('/auth/profile');
      if (response is Map<String, dynamic>) return response;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<bool> isLoggedIn() async => api.hasToken();

  static Future<void> saveToken(String token) async => api.setToken(token);

  static Future<void> clearToken() async => api.setToken(null);
}
