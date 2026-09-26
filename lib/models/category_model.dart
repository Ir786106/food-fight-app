class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int order;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? restaurantId;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.restaurantId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'order': order,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'restaurantId': restaurantId,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'] ?? json['categoryImage'],
      order: json['order'] ?? 0,
      isActive: json['isActive'] == 1 || json['isActive'] == true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
      restaurantId: json['restaurantId'] ?? json['restaurant_id'],
    );
  }
}
