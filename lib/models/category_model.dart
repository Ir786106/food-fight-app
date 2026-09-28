import '../core/utils/safe_convert.dart';

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
  final String? branchId;

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
    this.branchId,
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
      if (branchId != null) 'branchId': branchId,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? json['categoryImage']?.toString(),
      order: SafeConvert.toInt(json['order']),
      isActive: json['isActive'] == 1 || json['isActive'] == true,
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
      restaurantId: json['restaurantId']?.toString() ?? json['restaurant_id']?.toString(),
      branchId: json['branchId']?.toString() ?? json['branch_id']?.toString(),
    );
  }
}
