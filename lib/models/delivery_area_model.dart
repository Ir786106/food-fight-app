import '../core/utils/safe_convert.dart';

class DeliveryAreaModel {
  final String id;
  final String name;
  final double deliveryCharge;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? branchId;

  DeliveryAreaModel({
    required this.id,
    required this.name,
    required this.deliveryCharge,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.branchId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deliveryCharge': deliveryCharge,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'description': description,
      if (branchId != null) 'branchId': branchId,
    };
  }

  factory DeliveryAreaModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAreaModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      deliveryCharge: SafeConvert.toDouble(json['deliveryCharge'] ?? json['delivery_fee']),
      isActive: json['isActive'] == 1 || json['isActive'] == true,
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
      description: json['description']?.toString(),
      branchId: json['branchId']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryAreaModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
