class RiderModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? profileImage;
  final String? riderId;
  final bool isActive;
  final bool isOnline;
  final double rating;
  final int totalDeliveries;
  final DateTime createdAt;
  final DateTime updatedAt;

  RiderModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.profileImage,
    this.riderId,
    this.isActive = true,
    this.isOnline = false,
    this.rating = 0,
    this.totalDeliveries = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'riderId': riderId,
      'isActive': isActive ? 1 : 0,
      'isOnline': isOnline ? 1 : 0,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'],
      riderId: json['riderId'] ?? json['rider_id'],
      isActive: json['isActive'] == 1 || json['isActive'] == true,
      isOnline: json['isOnline'] == 1 || json['isOnline'] == true,
      rating: (json['rating'] ?? 0).toDouble(),
      totalDeliveries: json['totalDeliveries'] ?? json['total_deliveries'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
    );
  }
}
