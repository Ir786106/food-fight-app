import '../core/utils/safe_convert.dart';
import 'cart_item_model.dart';

enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  assigned,
  pickedUp,
  outForDelivery,
  delivered,
  cancelled;

  static OrderStatus fromString(String? value) {
    final normalized =
        (value ?? '').toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    if (normalized == 'canceled' || normalized == 'failed') return cancelled;
    return values.firstWhere(
      (status) => status.name.toLowerCase() == normalized,
      orElse: () => pending,
    );
  }
}

extension OrderStatusExtension on OrderStatus {
  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled;

  bool get isBroadcasting =>
      this == OrderStatus.pickedUp || this == OrderStatus.outForDelivery;

  OrderStatus? get nextStatus => switch (this) {
        OrderStatus.pending => OrderStatus.accepted,
        OrderStatus.accepted => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.ready,
        OrderStatus.ready => OrderStatus.assigned,
        OrderStatus.assigned => OrderStatus.pickedUp,
        OrderStatus.pickedUp => OrderStatus.outForDelivery,
        OrderStatus.outForDelivery => OrderStatus.delivered,
        OrderStatus.delivered || OrderStatus.cancelled => null,
      };

  bool canTransitionTo(OrderStatus next) =>
      !isTerminal && (next == nextStatus || next == OrderStatus.cancelled);

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

/// A recorded lifecycle event. Missing legacy history stays empty; no times are invented.
class OrderStatusEvent {
  final OrderStatus status;
  final DateTime timestamp;
  final String actorId;
  final String? reason;
  final String? action;

  const OrderStatusEvent(
      {required this.status,
      required this.timestamp,
      required this.actorId,
      this.reason,
      this.action});

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) =>
      OrderStatusEvent(
        status: OrderStatus.fromString(json['status']?.toString()),
        timestamp: SafeConvert.toDateTime(
            json['timestamp'], DateTime.fromMillisecondsSinceEpoch(0)),
        actorId: json['actorId']?.toString() ?? '',
        reason: json['reason']?.toString(),
        action: json['action']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'actorId': actorId,
        if (reason != null) 'reason': reason,
        if (action != null) 'action': action,
      };
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
  final String? codSettlementStatus;
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
  final int tokensUsed;
  final double tokensDiscount;
  final List<OrderStatusEvent> statusHistory;
  final DateTime? riderAcceptedAt;
  final DateTime? offerExpiresAt;
  final DateTime? deliveredAt;

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
    this.codSettlementStatus,
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
    this.restaurantName = 'Food Fight',
    this.branchId,
    this.tokensUsed = 0,
    this.tokensDiscount = 0.0,
    this.statusHistory = const [],
    this.riderAcceptedAt,
    this.offerExpiresAt,
    this.deliveredAt,
  });

  String get statusLabel => status.displayName;

  DateTime? timestampFor(OrderStatus value) {
    for (final event in statusHistory.reversed) {
      if (event.status == value && event.timestamp.millisecondsSinceEpoch > 0)
        return event.timestamp;
    }
    if (value == OrderStatus.pending) return createdAt;
    if (value == OrderStatus.delivered) return deliveredAt;
    return null;
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
      if (codSettlementStatus != null)
        'codSettlementStatus': codSettlementStatus,
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
      'tokensUsed': tokensUsed,
      'tokensDiscount': tokensDiscount,
      'statusHistory': statusHistory.map((event) => event.toJson()).toList(),
      if (offerExpiresAt != null)
        'offerExpiresAt': offerExpiresAt!.millisecondsSinceEpoch,
      if (riderAcceptedAt != null)
        'riderAcceptedAt': riderAcceptedAt!.millisecondsSinceEpoch,
      if (deliveredAt != null)
        'deliveredAt': deliveredAt!.millisecondsSinceEpoch,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<CartItemModel> items = [];
    if (rawItems is List) {
      items = rawItems
          .whereType<Map>()
          .map(
              (item) => CartItemModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      items: items,
      subtotal: SafeConvert.toDouble(json['subtotal']),
      discount: SafeConvert.toDouble(json['discount']),
      deliveryCharge: SafeConvert.toDouble(json['deliveryCharge'] ??
          json['deliveryFee'] ??
          json['delivery_charge']),
      total: SafeConvert.toDouble(json['total']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash on Delivery',
      paymentStatus: json['paymentStatus']?.toString() ??
          json['payment_status']?.toString() ??
          'pending',
      codSettlementStatus: json['codSettlementStatus']?.toString(),
      status: OrderStatus.fromString(json['status']?.toString()),
      deliveryAddress: json['deliveryAddress']?.toString() ??
          json['delivery_address']?.toString() ??
          '',
      riderId: json['riderId']?.toString() ?? json['rider_id']?.toString(),
      riderName:
          json['riderName']?.toString() ?? json['rider_name']?.toString(),
      riderPhone:
          json['riderPhone']?.toString() ?? json['rider_phone']?.toString(),
      cancellationReason: json['cancellationReason']?.toString() ??
          json['cancellation_reason']?.toString(),
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
      customerId: json['customerId']?.toString() ??
          json['customer_id']?.toString() ??
          '',
      customerName: json['customerName']?.toString() ??
          json['customer_name']?.toString() ??
          'Guest Customer',
      customerPhone: json['customerPhone']?.toString() ??
          json['customer_phone']?.toString() ??
          '',
      restaurantName: json['restaurantName']?.toString() ??
          json['restaurant_name']?.toString() ??
          '',
      branchId: json['branchId']?.toString() ?? json['branch_id']?.toString(),
      tokensUsed:
          SafeConvert.toInt(json['tokensUsed'] ?? json['tokensRedeemed']),
      tokensDiscount: SafeConvert.toDouble(
          json['tokensDiscount'] ?? json['loyaltyDiscount']),
      statusHistory: json['statusHistory'] is List
          ? (json['statusHistory'] as List)
              .whereType<Map>()
              .map((event) =>
                  OrderStatusEvent.fromJson(Map<String, dynamic>.from(event)))
              .toList()
          : const [],
      offerExpiresAt: json['offerExpiresAt'] == null
          ? null
          : SafeConvert.toDateTime(json['offerExpiresAt']),
      riderAcceptedAt: json['riderAcceptedAt'] == null
          ? null
          : SafeConvert.toDateTime(json['riderAcceptedAt']),
      deliveredAt: json['deliveredAt'] == null
          ? null
          : SafeConvert.toDateTime(json['deliveredAt']),
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
    String? codSettlementStatus,
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
    int? tokensUsed,
    double? tokensDiscount,
    List<OrderStatusEvent>? statusHistory,
    DateTime? riderAcceptedAt,
    DateTime? offerExpiresAt,
    DateTime? deliveredAt,
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
      codSettlementStatus: codSettlementStatus ?? this.codSettlementStatus,
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
      tokensUsed: tokensUsed ?? this.tokensUsed,
      tokensDiscount: tokensDiscount ?? this.tokensDiscount,
      statusHistory: statusHistory ?? this.statusHistory,
      offerExpiresAt: offerExpiresAt ?? this.offerExpiresAt,
      riderAcceptedAt: riderAcceptedAt ?? this.riderAcceptedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
