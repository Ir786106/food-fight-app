class DeliveryAreaModel {
  final String id;
  final String name;
  final double deliveryCharge;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;

  DeliveryAreaModel({
    required this.id,
    required this.name,
    required this.deliveryCharge,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.description,
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
    };
  }

  factory DeliveryAreaModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAreaModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      deliveryCharge: (json['deliveryCharge'] ?? json['delivery_fee'] ?? 0).toDouble(),
      isActive: json['isActive'] == 1 || json['isActive'] == true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
      description: json['description'],
    );
  }
}
