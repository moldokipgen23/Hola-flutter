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
    // Phase 3: three buckets — Shopping, Booking, Directory. Ride is folded
    // into Booking and must never be offered as a tab.
    worlds: {'shop': true, 'book': true, 'discover': true},
    modules: {
      'catalog': true,
      'orders': true,
      'inventory': true,
      'bookings': true,
      'transport': true,
      'turf': true,
    },
    experiences: {
      'directory': true,
      'retail': true,
      'restaurant': true,
      'appointment': true,
      'stay': true,
      'turf': true,
      'taxi': true,
      'shared_transport': true,
      'vehicle_rental': true,
      'goods_transport': true,
      'seat_event': true,
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
