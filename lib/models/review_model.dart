import '../core/utils/safe_convert.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String orderId;
  final String itemId;
  final double rating;
  final String? reviewText;
  final List<String>? imageUrls;
  final String? userName;
  final String? userAvatar;
  final String? branchId;
  final String targetType; // 'item', 'branch', 'rider'
  final String? adminReply;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get comment => reviewText ?? '';

  ReviewModel({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.itemId,
    required this.rating,
    this.reviewText,
    this.imageUrls,
    this.userName,
    this.userAvatar,
    this.branchId,
    this.targetType = 'item',
    this.adminReply,
    this.isHidden = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderId': orderId,
      'itemId': itemId,
      'rating': rating,
      'reviewText': reviewText,
      'imageUrls': imageUrls,
      if (userName != null) 'userName': userName,
      if (userAvatar != null) 'userAvatar': userAvatar,
      if (branchId != null) 'branchId': branchId,
      'targetType': targetType,
      if (adminReply != null) 'adminReply': adminReply,
      'isHidden': isHidden,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? json['item_id']?.toString() ?? '',
      rating: SafeConvert.toDouble(json['rating'], 5.0),
      reviewText: json['reviewText']?.toString() ?? json['review_text']?.toString(),
      imageUrls: json['imageUrls'] != null && json['imageUrls'] is List
          ? (json['imageUrls'] as List).map((e) => e.toString()).toList()
          : null,
      userName: json['userName']?.toString(),
      userAvatar: json['userAvatar']?.toString(),
      branchId: json['branchId']?.toString(),
      targetType: json['targetType']?.toString() ?? 'item',
      adminReply: json['adminReply']?.toString(),
      isHidden: json['isHidden'] == true || json['isHidden'] == 1,
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
    );
  }

  ReviewModel copyWith({
    String? id,
    String? userId,
    String? orderId,
    String? itemId,
    double? rating,
    String? reviewText,
    List<String>? imageUrls,
    String? userName,
    String? userAvatar,
    String? branchId,
    String? targetType,
    String? adminReply,
    bool? isHidden,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      itemId: itemId ?? this.itemId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      imageUrls: imageUrls ?? this.imageUrls,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      branchId: branchId ?? this.branchId,
      targetType: targetType ?? this.targetType,
      adminReply: adminReply ?? this.adminReply,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
