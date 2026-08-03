import 'package:flutter/material.dart';

class CategoryIcons {
  static const Map<String, IconData> _iconMap = {
    // Food & Restaurants
    'food & restaurants': Icons.restaurant_rounded,
    'restaurants': Icons.restaurant_rounded,
    'cafes': Icons.coffee_rounded,
    'bakeries': Icons.bakery_dining_rounded,
    'fast food': Icons.lunch_dining_rounded,
    'catering': Icons.deck_rounded,
    'street food': Icons.food_bank_rounded,

    // Hotels & Lodges
    'hotels & lodges': Icons.hotel_rounded,
    'hotels': Icons.hotel_rounded,
    'resorts': Icons.pool_rounded,
    'guest houses': Icons.villa_rounded,
    'homestays': Icons.cottage_rounded,

    // Healthcare
    'healthcare': Icons.local_hospital_rounded,
    'hospitals': Icons.local_hospital_rounded,
    'pharmacies': Icons.local_pharmacy_rounded,
    'clinics': Icons.medical_services_rounded,
    'dental': Icons.clean_hands_rounded,
    'diagnostic lab': Icons.science_rounded,

    // Education
    'education': Icons.school_rounded,
    'schools': Icons.school_rounded,
    'colleges': Icons.account_balance_rounded,
    'tuition centers': Icons.menu_book_rounded,
    'preschool': Icons.child_care_rounded,
    'music school': Icons.music_note_rounded,
    'dance school': Icons.directions_run_rounded,

    // Shopping & Retail
    'shopping & retail': Icons.shopping_bag_rounded,
    'shopping mall': Icons.shopping_cart_rounded,
    'grocery stores': Icons.local_grocery_store_rounded,
    'clothing': Icons.checkroom_rounded,
    'hardware stores': Icons.hardware_rounded,
    'stationery': Icons.edit_note_rounded,
    'electronics store': Icons.devices_rounded,

    // Electronics & Tech
    'electronics & tech': Icons.devices_rounded,
    'mobile shops': Icons.smartphone_rounded,
    'computer stores': Icons.computer_rounded,
    'repair shops': Icons.build_rounded,

    // Automobiles
    'automobiles': Icons.directions_car_rounded,
    'car dealers': Icons.directions_car_rounded,
    'bike shops': Icons.two_wheeler_rounded,
    'service centers': Icons.car_repair_rounded,

    // Beauty & Wellness
    'beauty & wellness': Icons.content_cut_rounded,
    'salons': Icons.content_cut_rounded,
    'spas': Icons.spa_rounded,
    'beauty parlours': Icons.face_rounded,

    // Professional Services
    'professional services': Icons.business_center_rounded,
    'banks': Icons.account_balance_rounded,
    'insurance': Icons.security_rounded,
    'legal services': Icons.gavel_rounded,
    'travel agents': Icons.flight_rounded,

    // Sports & Fitness
    'sports & fitness': Icons.fitness_center_rounded,
    'gyms': Icons.fitness_center_rounded,
    'football turf': Icons.sports_soccer_rounded,
    'swimming pool': Icons.pool_rounded,
    'picnic spot': Icons.park_rounded,
    'amusement park': Icons.roller_skating_rounded,
    'sports shops': Icons.sports_football_rounded,

    // General
    'general': Icons.store_rounded,
    'establishment': Icons.apartment_rounded,

    // Worship
    'churches': Icons.church_rounded,
    'temples': Icons.temple_hindu_rounded,
    'mosques': Icons.mosque_rounded,

    // Public
    'banks & atms': Icons.atm_rounded,
    'post office': Icons.markunread_mailbox_rounded,
    'police station': Icons.local_police_rounded,
    'fire station': Icons.fire_truck_rounded,
    'community hall': Icons.groups_rounded,
    'government offices': Icons.account_balance_rounded,
    'petrol pumps': Icons.local_gas_station_rounded,
  };

  static IconData getIcon(String? categoryName) {
    if (categoryName == null) return Icons.store_rounded;
    final lower = categoryName.toLowerCase();
    // Exact match first
    if (_iconMap.containsKey(lower)) return _iconMap[lower]!;
    // Partial match
    for (final entry in _iconMap.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }
    return Icons.store_rounded;
  }

  static Color getColor(String? categoryName) {
    if (categoryName == null) return const Color(0xFF3B82F6);
    final lower = categoryName.toLowerCase();

    if (lower.contains('food') ||
        lower.contains('restaurant') ||
        lower.contains('cafe') ||
        lower.contains('bakery')) {
      return const Color(0xFFF97316); // Orange
    }
    if (lower.contains('hotel') ||
        lower.contains('lodge') ||
        lower.contains('resort')) {
      return const Color(0xFF3B82F6); // Blue
    }
    if (lower.contains('health') ||
        lower.contains('hospital') ||
        lower.contains('pharm') ||
        lower.contains('clinic')) {
      return const Color(0xFF10B981); // Green
    }
    if (lower.contains('education') ||
        lower.contains('school') ||
        lower.contains('college')) {
      return const Color(0xFF8B5CF6); // Purple
    }
    if (lower.contains('shopping') ||
        lower.contains('retail') ||
        lower.contains('store') ||
        lower.contains('mall')) {
      return const Color(0xFFEC4899); // Pink
    }
    if (lower.contains('electron') ||
        lower.contains('computer') ||
        lower.contains('mobile') ||
        lower.contains('tech')) {
      return const Color(0xFF06B6D4); // Cyan
    }
    if (lower.contains('auto') ||
        lower.contains('car') ||
        lower.contains('bike')) {
      return const Color(0xFF64748B); // Slate
    }
    if (lower.contains('beauty') ||
        lower.contains('salon') ||
        lower.contains('spa')) {
      return const Color(0xFFF43F5E); // Rose
    }
    if (lower.contains('sport') ||
        lower.contains('gym') ||
        lower.contains('fitness') ||
        lower.contains('football') ||
        lower.contains('pool')) {
      return const Color(0xFF14B8A6); // Teal
    }
    if (lower.contains('bank') || lower.contains('professional')) {
      return const Color(0xFF6366F1); // Indigo
    }
    return const Color(0xFF3B82F6); // Default blue
  }

  static LinearGradient getGradient(String? categoryName) {
    final color = getColor(categoryName);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color, color.withValues(alpha: 0.7)],
    );
  }
}
