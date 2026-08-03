import 'package:flutter/material.dart';

class Booking {
  final int id;
  final int businessId;
  final int? serviceId;
  final int? userId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final DateTime bookingDate;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int durationMinutes;
  final int partySize;
  final int reservationUnits;
  final List<String> seatLabels;
  final double unitPrice;
  final double totalPrice;
  final String paymentStatus;
  final String paymentMethod;
  final String status;
  final String? notes;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Service? service;
  final String? businessName;
  final String? businessSlug;
  final String? businessPhoto;

  Booking({
    required this.id,
    required this.businessId,
    this.serviceId,
    this.userId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.bookingDate,
    this.checkInDate,
    this.checkOutDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.partySize,
    this.reservationUnits = 1,
    this.seatLabels = const [],
    this.unitPrice = 0,
    required this.totalPrice,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.status,
    this.notes,
    this.cancellationReason,
    this.cancelledAt,
    this.confirmedAt,
    this.completedAt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.service,
    this.businessName,
    this.businessSlug,
    this.businessPhoto,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      businessId: json['business_id'],
      serviceId: json['service_id'],
      userId: json['user_id'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      customerEmail: json['customer_email'],
      bookingDate: DateTime.parse(json['booking_date']),
      checkInDate: json['check_in_date'] != null
          ? DateTime.parse(json['check_in_date'])
          : null,
      checkOutDate: json['check_out_date'] != null
          ? DateTime.parse(json['check_out_date'])
          : null,
      startTime: _parseTime(json['start_time']),
      endTime: _parseTime(json['end_time']),
      durationMinutes: json['duration_minutes'] ?? 60,
      partySize: json['party_size'] ?? 1,
      reservationUnits: json['reservation_units'] ?? 1,
      seatLabels: json['seat_labels'] is List
          ? List<String>.from(json['seat_labels'])
          : const [],
      unitPrice: (json['unit_price'] ?? json['total_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'cash',
      status: json['status'],
      notes: json['notes'],
      cancellationReason: json['cancellation_reason'],
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      service: json['service'] != null
          ? Service.fromJson(json['service'])
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

  static TimeOfDay _parseTime(String? timeStr) {
    if (timeStr == null) return const TimeOfDay(hour: 9, minute: 0);
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isNoShow => status == 'no_show';

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'confirmed':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      case 'no_show':
        return const Color(0xFF9E9E9E);
      default:
        return Colors.grey;
    }
  }

  String get displayStatus {
    switch (status) {
      case 'no_show':
        return 'No Show';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  String get serviceName => service?.name ?? '';

  String timeRange() {
    final s =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final e =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$s - $e';
  }

  bool get isUpcoming =>
      bookingDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));
}

class Service {
  final int id;
  final int businessId;
  final String name;
  final String? description;
  final double price;
  final int duration;
  final bool isActive;
  final int sortOrder;
  final bool hasFixedSlots;
  final String bookingMode;
  final int capacity;
  final int inventoryUnits;
  final String? unitLabel;
  final String priceUnit;
  final String? checkInTime;
  final String? checkOutTime;
  final int minStayNights;
  final int? maxStayNights;

  Service({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.price,
    required this.duration,
    required this.isActive,
    required this.sortOrder,
    this.hasFixedSlots = false,
    this.bookingMode = 'appointment',
    this.capacity = 1,
    this.inventoryUnits = 1,
    this.unitLabel,
    this.priceUnit = 'booking',
    this.checkInTime,
    this.checkOutTime,
    this.minStayNights = 1,
    this.maxStayNights,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      businessId: json['business_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      duration: json['duration'] ?? 60,
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      hasFixedSlots: json['has_fixed_slots'] ?? false,
      bookingMode: json['booking_mode'] ?? 'appointment',
      capacity: json['capacity'] ?? 1,
      inventoryUnits: json['inventory_units'] ?? 1,
      unitLabel: json['unit_label'],
      priceUnit: json['price_unit'] ?? 'booking',
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      minStayNights: json['min_stay_nights'] ?? 1,
      maxStayNights: json['max_stay_nights'],
    );
  }
}
