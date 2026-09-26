import '../core/utils/safe_convert.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String orderId;
  final String itemId;
  final double rating;
  final String? reviewText;
  final List<String>? imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.itemId,
    required this.rating,
    this.reviewText,
    this.imageUrls,
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
      rating: SafeConvert.toDouble(json['rating']),
      reviewText: json['reviewText']?.toString() ?? json['review_text']?.toString(),
      imageUrls: json['imageUrls'] != null && json['imageUrls'] is List
          ? (json['imageUrls'] as List).map((e) => e.toString()).toList()
          : null,
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
    );
  }
}
