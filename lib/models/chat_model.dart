import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/safe_convert.dart';

/// Represents a customer support or order-linked real-time chat channel.
class ChatModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String branchId;
  final String? orderId;
  final String? orderNumber;
  final String type; // 'order' | 'support'
  final String status; // 'open' | 'pending' | 'resolved'
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastSenderRole; // 'customer' | 'admin' | 'super_admin'
  final int unreadForAdmin;
  final int unreadForCustomer;
  final String? assignedAdminId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.branchId,
    this.orderId,
    this.orderNumber,
    this.type = 'support',
    this.status = 'open',
    this.lastMessage = '',
    DateTime? lastMessageAt,
    this.lastSenderRole = 'customer',
    this.unreadForAdmin = 0,
    this.unreadForCustomer = 0,
    this.assignedAdminId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : lastMessageAt = lastMessageAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isOpen => status == 'open';
  bool get isPending => status == 'pending';
  bool get isResolved => status == 'resolved';
  bool get isOrderChat => type == 'order' && orderId != null && orderId!.isNotEmpty;

  ChatModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? branchId,
    String? orderId,
    String? orderNumber,
    String? type,
    String? status,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastSenderRole,
    int? unreadForAdmin,
    int? unreadForCustomer,
    String? assignedAdminId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      branchId: branchId ?? this.branchId,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastSenderRole: lastSenderRole ?? this.lastSenderRole,
      unreadForAdmin: unreadForAdmin ?? this.unreadForAdmin,
      unreadForCustomer: unreadForCustomer ?? this.unreadForCustomer,
      assignedAdminId: assignedAdminId ?? this.assignedAdminId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'branchId': branchId,
      if (orderId != null) 'orderId': orderId,
      if (orderNumber != null) 'orderNumber': orderNumber,
      'type': type,
      'status': status,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastSenderRole': lastSenderRole,
      'unreadForAdmin': unreadForAdmin,
      'unreadForCustomer': unreadForCustomer,
      if (assignedAdminId != null) 'assignedAdminId': assignedAdminId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory ChatModel.fromMap(Map<String, dynamic> map, [String? id]) =>
      ChatModel.fromJson(map, id);

  factory ChatModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return ChatModel(
      id: docId ?? json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Customer',
      customerPhone: json['customerPhone']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      orderNumber: json['orderNumber']?.toString(),
      type: json['type']?.toString() ?? 'support',
      status: json['status']?.toString() ?? 'open',
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageAt: SafeConvert.toDateTime(json['lastMessageAt']),
      lastSenderRole: json['lastSenderRole']?.toString() ?? 'customer',
      unreadForAdmin: SafeConvert.toInt(json['unreadForAdmin']),
      unreadForCustomer: SafeConvert.toInt(json['unreadForCustomer']),
      assignedAdminId: json['assignedAdminId']?.toString(),
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
    );
  }
}
