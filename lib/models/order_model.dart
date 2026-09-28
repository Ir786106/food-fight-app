import '../core/utils/safe_convert.dart';
import 'cart_item_model.dart';

enum OrderStatus { pending, accepted, preparing, ready, assigned, pickedUp, outForDelivery, delivered, cancelled }

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
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
}

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
  final String? riderName;
  final String? riderPhone;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String restaurantName;
  final String? branchId;

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
    this.riderName,
    this.riderPhone,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    required this.customerId,
    this.customerName = 'Guest Customer',
    this.customerPhone = '',
    required this.restaurantName,
    this.branchId,
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
      'riderName': riderName,
      'riderPhone': riderPhone,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'restaurantName': restaurantName,
      if (branchId != null) 'branchId': branchId,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<CartItemModel> items = [];
    if (rawItems is List) {
      items = rawItems
          .whereType<Map>()
          .map((item) => CartItemModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    
    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      items: items,
      subtotal: SafeConvert.toDouble(json['subtotal']),
      discount: SafeConvert.toDouble(json['discount']),
      deliveryCharge: SafeConvert.toDouble(json['deliveryCharge'] ?? json['delivery_charge']),
      total: SafeConvert.toDouble(json['total']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash on Delivery',
      paymentStatus: json['paymentStatus']?.toString() ?? json['payment_status']?.toString() ?? 'pending',
      status: _getStatusFromString(json['status']?.toString()),
      deliveryAddress: json['deliveryAddress']?.toString() ?? json['delivery_address']?.toString() ?? '',
      riderId: json['riderId']?.toString() ?? json['rider_id']?.toString(),
      riderName: json['riderName']?.toString() ?? json['rider_name']?.toString(),
      riderPhone: json['riderPhone']?.toString() ?? json['rider_phone']?.toString(),
      cancellationReason: json['cancellationReason']?.toString() ?? json['cancellation_reason']?.toString(),
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
      customerId: json['customerId']?.toString() ?? json['customer_id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? json['customer_name']?.toString() ?? 'Guest Customer',
      customerPhone: json['customerPhone']?.toString() ?? json['customer_phone']?.toString() ?? '',
      restaurantName: json['restaurantName']?.toString() ?? json['restaurant_name']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? json['branch_id']?.toString(),
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
    String? riderName,
    String? riderPhone,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? restaurantName,
    String? branchId,
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
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      restaurantName: restaurantName ?? this.restaurantName,
      branchId: branchId ?? this.branchId,
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
      case 'pickedup':
      case 'picked_up':
      case 'picked up':
        return OrderStatus.pickedUp;
      case 'outfordelivery':
      case 'out_for_delivery':
      case 'out for delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}
