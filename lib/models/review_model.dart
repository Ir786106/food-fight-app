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
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      orderId: json['orderId'] ?? json['order_id'] ?? '',
      itemId: json['itemId'] ?? json['item_id'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewText: json['reviewText'] ?? json['review_text'],
      imageUrls: json['imageUrls'] != null 
          ? List<String>.from(json['imageUrls'] as List)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
    );
  }
}
