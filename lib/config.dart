// Centralized configuration. Values can be overridden at build time with:
//   flutter run/build --dart-define=API_BASE_URL=https://api.example.com/api
//                    --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
//
// Defaults below point at the local Laravel backend over HTTP for emulator
// development. Replace the defaults (or pass --dart-define) for production.

class AppConfig {
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'https://hola.ehlom.com/api');

  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

  /// Public origin used to turn backend-relative storage paths
  /// (e.g. "storage/photos/foo.jpg") into absolute URLs.
  /// Derived from apiBaseUrl by stripping the "/api" suffix.
  static String get storageBaseUrl {
    final url = Uri.parse(apiBaseUrl);
    final origin = url.origin; // scheme://host(:port)
    return origin;
  }
}
