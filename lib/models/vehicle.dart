class Vehicle {
  final int id;
  final int businessId;
  final String name;
  final String type;
  final String serviceMode;
  final int seats;
  final double? capacityValue;
  final String capacityUnit;
  final double baseFare;
  final double farePerKm;
  final bool requiresQuote;
  final int minKm;
  final String? registrationNumber;
  final String? image;
  final String? description;
  final bool isActive;
  final bool isRequestable;
  final String availabilityStatus;
  final int sortOrder;

  Vehicle({
    required this.id,
    required this.businessId,
    required this.name,
    required this.type,
    this.serviceMode = 'taxi',
    required this.seats,
    this.capacityValue,
    this.capacityUnit = 'seats',
    required this.baseFare,
    required this.farePerKm,
    this.requiresQuote = false,
    this.minKm = 1,
    this.registrationNumber,
    this.image,
    this.description,
    this.isActive = true,
    this.isRequestable = true,
    this.availabilityStatus = 'available',
    this.sortOrder = 0,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      businessId: json['business_id'],
      name: json['name'],
      type: json['type'] ?? 'car',
      serviceMode: json['service_mode'] ?? 'taxi',
      seats: json['seats'] ?? 4,
      capacityValue: json['capacity_value']?.toDouble(),
      capacityUnit: json['capacity_unit'] ?? 'seats',
      baseFare: (json['base_fare'] ?? 0).toDouble(),
      farePerKm: (json['fare_per_km'] ?? 0).toDouble(),
      requiresQuote: json['requires_quote'] ?? false,
      minKm: json['min_km'] ?? 1,
      registrationNumber: json['registration_number'],
      image: json['image'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
      isRequestable: json['is_requestable'] ?? true,
      availabilityStatus: json['availability_status'] ?? 'available',
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  double estimatedFare(double distanceKm) {
    final dist = distanceKm < minKm ? minKm.toDouble() : distanceKm;
    return baseFare + (dist * farePerKm);
  }

  String get typeIcon {
    switch (type) {
      case 'car':
        return '🚗';
      case 'bolero':
        return '🚙';
      case 'suv':
        return '🚙';
      case 'van':
        return '🚐';
      case 'auto':
        return '🛺';
      case 'bike':
        return '🏍️';
      case 'bus':
        return '🚌';
      case 'truck':
        return '🚛';
      case 'pickup':
        return '🛻';
      case 'tempo':
        return '🚚';
      default:
        return '🚗';
    }
  }
}

class Trip {
  final int id;
  final int businessId;
  final int? vehicleId;
  final int? userId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String pickupLocation;
  final String dropLocation;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final double? distanceKm;
  final double fare;
  final int seatsRequired;
  final String? driverName;
  final String? driverPhone;
  final String status;
  final String? tripDate;
  final String? tripTime;
  final String requestType;
  final DateTime? scheduledAt;
  final DateTime? returnAt;
  final String fareStatus;
  final String paymentStatus;
  final String? loadDescription;
  final double? loadWeight;
  final String? cancellationReason;
  final String? notes;
  final String createdAt;
  final Vehicle? vehicle;
  final String? businessName;
  final String? businessSlug;
  final String? businessPhoto;

  Trip({
    required this.id,
    required this.businessId,
    this.vehicleId,
    this.userId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.pickupLocation,
    required this.dropLocation,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.distanceKm,
    required this.fare,
    this.seatsRequired = 1,
    this.driverName,
    this.driverPhone,
    required this.status,
    this.tripDate,
    this.tripTime,
    this.requestType = 'ride',
    this.scheduledAt,
    this.returnAt,
    this.fareStatus = 'estimated',
    this.paymentStatus = 'pending',
    this.loadDescription,
    this.loadWeight,
    this.cancellationReason,
    this.notes,
    required this.createdAt,
    this.vehicle,
    this.businessName,
    this.businessSlug,
    this.businessPhoto,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      businessId: json['business_id'],
      vehicleId: json['vehicle_id'],
      userId: json['user_id'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      customerEmail: json['customer_email'],
      pickupLocation: json['pickup_location'],
      dropLocation: json['drop_location'],
      pickupLat: json['pickup_lat']?.toDouble(),
      pickupLng: json['pickup_lng']?.toDouble(),
      dropLat: json['drop_lat']?.toDouble(),
      dropLng: json['drop_lng']?.toDouble(),
      distanceKm: json['distance_km']?.toDouble(),
      fare: (json['fare'] ?? 0).toDouble(),
      seatsRequired: json['seats_required'] ?? 1,
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      status: json['status'] ?? 'pending',
      tripDate: json['trip_date'],
      tripTime: json['trip_time'],
      requestType: json['request_type'] ?? 'ride',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,
      returnAt: json['return_at'] != null
          ? DateTime.parse(json['return_at'])
          : null,
      fareStatus: json['fare_status'] ?? 'estimated',
      paymentStatus: json['payment_status'] ?? 'pending',
      loadDescription: json['load_description'],
      loadWeight: json['load_weight']?.toDouble(),
      cancellationReason: json['cancellation_reason'],
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
      vehicle: json['vehicle'] != null
          ? Vehicle.fromJson(json['vehicle'])
          : null,
      businessName: json['business'] is Map ? json['business']['name'] : null,
      businessSlug: json['business'] is Map ? json['business']['slug'] : null,
      businessPhoto: json['business'] is Map
          ? (json['business']['photos'] is List &&
                    (json['business']['photos'] as List).isNotEmpty
                ? (json['business']['photos'] as List).first.toString()
                : null)
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isStarted => status == 'started';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}

class DeliveryZone {
  final int id;
  final int businessId;
  final int areaId;
  final double? minOrderAmount;
  final double deliveryFee;
  final int? estimatedMinutes;
  final bool isActive;
  final String? areaName;
  final List<String> pincodes;

  DeliveryZone({
    required this.id,
    required this.businessId,
    required this.areaId,
    this.minOrderAmount,
    required this.deliveryFee,
    this.estimatedMinutes,
    this.isActive = true,
    this.areaName,
    this.pincodes = const [],
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: json['id'],
      businessId: json['business_id'],
      areaId: json['area_id'],
      minOrderAmount: json['min_order_amount']?.toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      estimatedMinutes: json['estimated_minutes'],
      isActive: json['is_active'] ?? true,
      areaName: json['area'] is Map ? json['area']['name'] : null,
      pincodes: json['pincodes'] != null
          ? List<String>.from(json['pincodes'])
          : [],
    );
  }
}

class TimeSlot {
  final int id;
  final int serviceId;
  final int? dayOfWeek;
  final String startTime;
  final String endTime;
  final int capacity;
  final double? priceOverride;
  final bool isActive;
  final int available;

  TimeSlot({
    required this.id,
    required this.serviceId,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    this.priceOverride,
    this.isActive = true,
    this.available = 0,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'],
      serviceId: json['service_id'],
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      capacity: json['capacity'] ?? 1,
      priceOverride: json['price_override']?.toDouble(),
      isActive: json['is_active'] ?? true,
      available: json['available'] ?? 0,
    );
  }

  double get price => priceOverride ?? 0;
  bool get isAvailable => available > 0;
}
