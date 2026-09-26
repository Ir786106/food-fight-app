class FavoritesModel {
  final String id;
  final String userId;
  final String itemId;
  final DateTime createdAt;

  FavoritesModel({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'itemId': itemId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory FavoritesModel.fromJson(Map<String, dynamic> json) {
    return FavoritesModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      itemId: json['itemId'] ?? json['item_id'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
    );
  }
}
