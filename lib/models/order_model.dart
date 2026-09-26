import 'cart_item_model.dart';

enum OrderStatus { pending, accepted, preparing, ready, assigned, pickedUp, outForDelivery, delivered, cancelled }

class OrderModel {
  final String id;
  final String orderNumber;
  final List<CartItemModel> items;
  final double subtotal;
  final double discount;
  final double deliveryCharge;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  OrderStatus status;
  final String deliveryAddress;
  final String? riderId;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String restaurantName;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.deliveryCharge = 0,
    required this.total,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.status = OrderStatus.pending,
    required this.deliveryAddress,
    this.riderId,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    required this.customerId,
    this.customerName = 'Guest Customer',
    this.customerPhone = '',
    required this.restaurantName,
  });

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'deliveryCharge': deliveryCharge,
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status.name,
      'deliveryAddress': deliveryAddress,
      'riderId': riderId,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'restaurantName': restaurantName,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
        ?.map((item) => CartItemModel.fromJson(item))
        .toList() ?? [];
    
    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      items: items,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      deliveryCharge: (json['deliveryCharge'] ?? json['delivery_charge'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'Cash on Delivery',
      paymentStatus: json['paymentStatus'] ?? json['payment_status'] ?? 'pending',
      status: _getStatusFromString(json['status']),
      deliveryAddress: json['deliveryAddress'] ?? json['delivery_address'] ?? '',
      riderId: json['riderId'] ?? json['rider_id'],
      cancellationReason: json['cancellationReason'] ?? json['cancellation_reason'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
      customerId: json['customerId'] ?? json['customer_id'] ?? '',
      customerName: json['customerName'] ?? json['customer_name'] ?? 'Guest Customer',
      customerPhone: json['customerPhone'] ?? json['customer_phone'] ?? '',
      restaurantName: json['restaurantName'] ?? json['restaurant_name'] ?? '',
    );
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    List<CartItemModel>? items,
    double? subtotal,
    double? discount,
    double? deliveryCharge,
    double? total,
    String? paymentMethod,
    String? paymentStatus,
    OrderStatus? status,
    String? deliveryAddress,
    String? riderId,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? restaurantName,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      riderId: riderId ?? this.riderId,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }

  static OrderStatus _getStatusFromString(String? status) {
    if (status == null) return OrderStatus.pending;
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'assigned':
        return OrderStatus.assigned;
      case 'picked up':
        return OrderStatus.pickedUp;
      case 'out for delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}
