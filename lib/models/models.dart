import 'booking.dart';
import 'vehicle.dart';

export 'booking.dart' show Booking, Service;
export 'order.dart' show Order, OrderItem;
export 'vehicle.dart' show Vehicle, Trip, DeliveryZone, TimeSlot;
export 'user.dart' show User;

class Category {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? image;
  final bool isActive;
  final bool isFeatured;
  final int businessesCount;
  final String moduleType;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.image,
    this.isActive = true,
    this.isFeatured = false,
    this.businessesCount = 0,
    this.moduleType = 'directory',
  });

  bool get isOrdering => moduleType == 'ordering';
  bool get isBooking => moduleType == 'booking';
  bool get isBoth => moduleType == 'both';
  bool get isDirectory => moduleType == 'directory';

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      icon: json['icon'],
      image: json['image'],
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      businessesCount: json['businesses_count'] ?? 0,
      moduleType: json['module_type'] ?? 'directory',
    );
  }
}

/// The `city` object returned on every business summary.
class CityRef {
  final int id;
  final String name;
  final String? slug;
  final String? state;

  const CityRef({
    required this.id,
    required this.name,
    this.slug,
    this.state,
  });

  factory CityRef.fromJson(Map<String, dynamic> json) => CityRef(
    id: json['id'],
    name: json['name']?.toString() ?? 'Unknown',
    slug: json['slug']?.toString(),
    state: json['state']?.toString(),
  );

  String get displayName =>
      (state != null && state!.isNotEmpty) ? '$name · $state' : name;
}

/// The `booking` capability object returned on every business summary.
/// Drives the card-level CTA: "Book" (in-app flow) or "Call/WhatsApp".
class BookingCapability {
  final bool canBookOnline;
  final String bookCta; // in_app | call_or_whatsapp | none
  final List<String> readyExperiences;
  final String? primaryExperience;
  final String? phone;
  final String? whatsapp;

  const BookingCapability({
    required this.canBookOnline,
    required this.bookCta,
    this.readyExperiences = const [],
    this.primaryExperience,
    this.phone,
    this.whatsapp,
  });

  factory BookingCapability.fromJson(Map<String, dynamic> json) {
    final contact = json['contact'];
    return BookingCapability(
      canBookOnline: json['can_book_online'] == true,
      bookCta: json['book_cta']?.toString() ?? 'none',
      readyExperiences:
          (json['ready_experiences'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      primaryExperience: json['primary_experience']?.toString(),
      phone: contact is Map ? contact['phone']?.toString() : null,
      whatsapp: contact is Map ? contact['whatsapp']?.toString() : null,
    );
  }

  bool get isInApp => bookCta == 'in_app';
  bool get isCallOrWhatsapp => bookCta == 'call_or_whatsapp';
  bool get canCall =>
      !canBookOnline && (phone != null && phone!.isNotEmpty);
  bool get canWhatsApp =>
      !canBookOnline && (whatsapp != null && whatsapp!.isNotEmpty);
}

class Business {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? address;
  final String? locality;
  final String? district;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? website;
  final List<String> photos;
  final Map<String, dynamic>? workingHours;
  final bool isActive;
  final bool isFeatured;
  final int viewsCount;
  final int savesCount;
  final int qualityScore;
  final double averageRating;
  final int reviewCount;
  final Category? category;
  final String? claimStatus;
  final String? distance;
  final bool? isSaved;
  final CityRef? city;
  final BookingCapability? booking;
  final List<String> experiences;
  final String? primaryExperience;
  final Map<String, dynamic>? primaryAction;

  // New fields
  final bool? isBookable;
  final int? priceRange;
  final String? serviceType;
  final Map<String, dynamic>? enabledModules;
  final Map<String, dynamic>? moduleConfig;
  final int? callCount;
  final int? whatsappCount;
  final int? directionsCount;
  final int? shareCount;
  final int? productsCount;
  final int? bookingsCount;
  final int? ordersCount;
  final List<Product> topProducts;
  final List<Service> topServices;
  final List<Vehicle> vehicles;
  final List<DeliveryZone> deliveryZones;

  Business({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.address,
    this.locality,
    this.district,
    this.lat,
    this.lng,
    this.phone,
    this.whatsapp,
    this.email,
    this.website,
    this.photos = const [],
    this.workingHours,
    this.isActive = true,
    this.isFeatured = false,
    this.viewsCount = 0,
    this.savesCount = 0,
    this.qualityScore = 0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.category,
    this.claimStatus,
    this.distance,
    this.isSaved,
    this.city,
    this.booking,
    this.experiences = const [],
    this.primaryExperience,
    this.primaryAction,
    this.isBookable,
    this.priceRange,
    this.serviceType,
    this.enabledModules,
    this.moduleConfig,
    this.callCount,
    this.whatsappCount,
    this.directionsCount,
    this.shareCount,
    this.productsCount,
    this.bookingsCount,
    this.ordersCount,
    this.topProducts = const [],
    this.topServices = const [],
    this.vehicles = const [],
    this.deliveryZones = const [],
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      address: json['address'],
      locality: json['locality'],
      district: json['district'],
      lat: json['latitude']?.toDouble() ?? json['lat']?.toDouble(),
      lng: json['longitude']?.toDouble() ?? json['lng']?.toDouble(),
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      email: json['email'],
      website: json['website'],
      photos: (json['photos'] as List?)
              ?.whereType<String>()
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      workingHours: json['working_hours'],
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      viewsCount: json['views_count'] ?? 0,
      savesCount: json['saves_count'] ?? 0,
      qualityScore: json['quality_score'] ?? 0,
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] is num
                ? (json['average_rating'] as num).toDouble()
                : double.tryParse(json['average_rating'].toString()) ?? 0.0)
          : 0.0,
      reviewCount: json['review_count'] ?? json['reviews_count'] ?? 0,
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      claimStatus: json['claim_status'],
      distance: json['distance']?.toString(),
      isSaved: json['is_saved'],
      city: json['city'] != null
          ? CityRef.fromJson(json['city'] as Map<String, dynamic>)
          : null,
      booking: json['booking'] != null
          ? BookingCapability.fromJson(json['booking'] as Map<String, dynamic>)
          : null,
      experiences: (json['experiences'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      primaryExperience: json['primary_experience']?.toString(),
      primaryAction: json['primary_action'],
      isBookable: json['is_bookable'],
      priceRange: json['price_range'],
      serviceType: json['service_type'],
      enabledModules: json['enabled_modules'] ?? json['capabilities'],
      moduleConfig: json['module_config'],
      callCount: json['call_count'],
      whatsappCount: json['whatsapp_count'],
      directionsCount: json['directions_count'],
      shareCount: json['share_count'],
      productsCount: json['products_count'],
      bookingsCount: json['bookings_count'],
      ordersCount: json['orders_count'],
      topProducts: json['products'] != null
          ? (json['products'] as List).map((p) => Product.fromJson(p)).toList()
          : [],
      topServices: json['services'] != null
          ? (json['services'] as List).map((s) => Service.fromJson(s)).toList()
          : [],
      vehicles: json['vehicles'] != null
          ? (json['vehicles'] as List).map((v) => Vehicle.fromJson(v)).toList()
          : [],
      deliveryZones: json['delivery_zones'] != null
          ? (json['delivery_zones'] as List)
                .map((z) => DeliveryZone.fromJson(z))
                .toList()
          : [],
    );
  }

  bool get hasCatalogModule => enabledModules?['catalog'] == true;
  bool get hasBookingsModule => enabledModules?['bookings'] == true;
  bool get hasOrdersModule => enabledModules?['orders'] == true;
  bool get hasInventoryModule => enabledModules?['inventory'] == true;
  bool get hasTransportModule => enabledModules?['transport'] == true;
  bool get hasTurfModule => enabledModules?['turf'] == true;
  bool get hasAnyBookingModule => hasBookingsModule || hasTurfModule;

  bool get canBookNow => booking?.canBookOnline == true;

  String? get bookingPhone =>
      booking?.phone != null ? booking!.phone : phone;
  String? get bookingWhatsApp =>
      booking?.whatsapp != null ? booking!.whatsapp : whatsapp;

  /// Human label for the primary in-app booking flow, e.g. "Book", "Reserve".
  String get bookCtaLabel {
    if (!canBookNow) return 'Book';
    switch (booking?.primaryExperience) {
      case 'stay':
        return 'Check Availability';
      case 'turf':
        return 'Book Slots';
      case 'seat_event':
        return 'Book Seats';
      default:
        return primaryAction?['label']?.toString() ?? 'Book Now';
    }
  }
}

class Product {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? menuSection;
  final String? foodType;
  final int? preparationMinutes;
  final String? availableFrom;
  final String? availableUntil;
  final String? soldOutUntil;
  final bool? isOrderable;
  final String? availabilityMessage;
  final String? image;
  final double? price;
  final String? availability;
  final Business? business;
  final int? stock;
  final bool? isActive;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.menuSection,
    this.foodType,
    this.preparationMinutes,
    this.availableFrom,
    this.availableUntil,
    this.soldOutUntil,
    this.isOrderable,
    this.availabilityMessage,
    this.image,
    this.price,
    this.availability,
    this.business,
    this.stock,
    this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      menuSection: json['menu_section'],
      foodType: json['food_type'],
      preparationMinutes: json['preparation_minutes'],
      availableFrom: json['available_from'],
      availableUntil: json['available_until'],
      soldOutUntil: json['sold_out_until'],
      isOrderable: json['is_orderable'],
      availabilityMessage: json['availability_message'],
      image: json['image'],
      price: json['price']?.toDouble(),
      availability: json['availability'],
      business: json['business'] != null
          ? Business.fromJson(json['business'])
          : null,
      stock: json['stock'],
      isActive: json['is_active'],
    );
  }

  String get displayPrice =>
      price != null ? '₹${price!.toStringAsFixed(0)}' : 'N/A';
  String get displayAvailability =>
      isActive == true ? 'In Stock' : 'Out of Stock';
  bool get isInStock =>
      isOrderable ??
      (isActive == true &&
          availability != 'out_of_stock' &&
          (stock == null || stock! > 0));
}

class Review {
  final int id;
  final int userId;
  final int businessId;
  final int rating;
  final String comment;
  final String userName;
  final String createdAt;
  final String? ownerResponse;

  Review({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.rating,
    this.comment = '',
    this.userName = '',
    this.createdAt = '',
    this.ownerResponse,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'],
      businessId: json['business_id'],
      rating: json['rating'],
      comment: json['comment'] ?? '',
      userName: json['user']?['name'] ?? '',
      createdAt: json['created_at'] ?? '',
      ownerResponse: json['owner_response'],
    );
  }
}
