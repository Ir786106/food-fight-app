import '../core/utils/safe_convert.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String? messageKey;
  final String? orderNumber;
  final String? orderStatus;
  final String type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.messageKey,
    this.orderNumber,
    this.orderStatus,
    required this.type,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      if (messageKey != null) 'messageKey': messageKey,
      if (orderNumber != null) 'orderNumber': orderNumber,
      if (orderStatus != null) 'orderStatus': orderStatus,
      'type': type,
      'referenceId': referenceId,
      'isRead': isRead ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      messageKey: json['messageKey'] as String?,
      orderNumber: json['orderNumber'] as String?,
      orderStatus: json['orderStatus'] as String?,
      type: json['type'] ?? 'general',
      referenceId: json['referenceId'] ?? json['reference_id'],
      isRead: json['isRead'] == 1 || json['isRead'] == true,
      createdAt: SafeConvert.toDateTime(
        json['createdAt'],
        DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  }

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      messageKey: messageKey,
      orderNumber: orderNumber,
      orderStatus: orderStatus,
      type: type,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
