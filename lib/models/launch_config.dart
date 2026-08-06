class LaunchConfig {
  final Map<String, bool> worlds;
  final Map<String, bool> modules;
  final Map<String, bool> experiences;
  final bool onlinePayments;

  const LaunchConfig({
    required this.worlds,
    required this.modules,
    required this.experiences,
    required this.onlinePayments,
  });

  factory LaunchConfig.defaults() => const LaunchConfig(
    // Launch scope: Directory + Booking only.
    // Shop & Taxi are dormant — server turns them on when ready.
    worlds: {'discover': true, 'book': true, 'shop': false},
    modules: {
      'bookings': true,
      'turf': true,
      'catalog': false,
      'orders': false,
      'inventory': false,
      'transport': false,
    },
    experiences: {
      'directory': true,
      'appointment': true,
      'stay': true,
      'turf': true,
      'retail': false,
      'restaurant': false,
      'taxi': false,
      'shared_transport': false,
      'vehicle_rental': false,
      'goods_transport': false,
      'seat_event': false,
    },
    onlinePayments: false,
  );

  factory LaunchConfig.fromJson(Map<String, dynamic> json) {
    Map<String, bool> boolMap(dynamic value, Map<String, bool> fallback) {
      if (value is! Map) return fallback;
      return {
        ...fallback,
        ...value.map((key, value) => MapEntry(key.toString(), value == true)),
      };
    }

    final defaults = LaunchConfig.defaults();
    final payments = json['payments'];
    return LaunchConfig(
      worlds: boolMap(json['worlds'], defaults.worlds),
      modules: boolMap(json['modules'], defaults.modules),
      experiences: boolMap(json['experiences'], defaults.experiences),
      onlinePayments: payments is Map && payments['online'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'worlds': worlds,
    'modules': modules,
    'experiences': experiences,
    'payments': {'online': onlinePayments},
  };

  bool world(String key) => worlds[key] ?? false;
  bool module(String key) => modules[key] ?? false;
  bool experience(String key) => experiences[key] ?? false;
}
