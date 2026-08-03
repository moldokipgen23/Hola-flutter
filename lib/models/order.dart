import 'package:flutter/material.dart';

class Order {
  final int id;
  final int businessId;
  final int? userId;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? deliveryAddress;
  final String deliveryMethod;
  final DateTime? estimatedReadyAt;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double discount;
  final double total;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? notes;
  final String? cancellationReason;
  final DateTime? confirmedAt;
  final DateTime? readyAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final String? businessName;
  final String? businessSlug;
  final String? businessPhoto;

  Order({
    required this.id,
    required this.businessId,
    this.userId,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.deliveryAddress,
    this.deliveryMethod = 'delivery',
    this.estimatedReadyAt,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.notes,
    this.cancellationReason,
    this.confirmedAt,
    this.readyAt,
    this.deliveredAt,
    this.cancelledAt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.businessName,
    this.businessSlug,
    this.businessPhoto,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      businessId: json['business_id'],
      userId: json['user_id'],
      orderNumber: json['order_number'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      customerEmail: json['customer_email'],
      deliveryAddress: json['delivery_address'],
      deliveryMethod: json['delivery_method'] ?? 'delivery',
      estimatedReadyAt: json['estimated_ready_at'] != null
          ? DateTime.parse(json['estimated_ready_at'])
          : null,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'],
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      cancellationReason: json['cancellation_reason'],
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      readyAt: json['ready_at'] != null
          ? DateTime.parse(json['ready_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items:
          (json['items'] as List?)
              ?.map((i) => OrderItem.fromJson(i))
              .toList() ??
          [],
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
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isOutForDelivery => status == 'out_for_delivery';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'confirmed':
        return const Color(0xFF2196F3);
      case 'preparing':
        return const Color(0xFF9C27B0);
      case 'ready':
        return const Color(0xFF00BCD4);
      case 'out_for_delivery':
        return const Color(0xFF3F51B5);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      case 'refunded':
        return const Color(0xFF795548);
      default:
        return Colors.grey;
    }
  }

  String get displayStatus {
    switch (status) {
      case 'out_for_delivery':
        return 'Out for Delivery';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int? productId;
  final String name;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, dynamic>? variants;
  final Map<String, dynamic>? metadata;

  OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    required this.name,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.variants,
    this.metadata,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      name: json['name'],
      description: json['description'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      variants: json['variants'],
      metadata: json['metadata'],
    );
  }
}
