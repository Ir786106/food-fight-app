import '../core/utils/safe_convert.dart';

class RiderModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? email;
  final String? profileImage;
  final String? riderId;
  final String? vehicleType;
  final String? vehicleNumber;
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
    this.email,
    this.profileImage,
    this.riderId,
    this.vehicleType = 'Motorcycle',
    this.vehicleNumber,
    this.isActive = true,
    this.isOnline = false,
    this.rating = 5.0,
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
      if (email != null && email!.isNotEmpty) 'email': email,
      'profileImage': profileImage,
      'riderId': riderId,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
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
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      profileImage: json['profileImage']?.toString(),
      riderId: json['riderId']?.toString() ?? json['rider_id']?.toString(),
      vehicleType: json['vehicleType']?.toString() ?? 'Motorcycle',
      vehicleNumber: json['vehicleNumber']?.toString(),
      isActive: json['isActive'] == 1 || json['isActive'] == true || json['isActive'] == null,
      isOnline: json['isOnline'] == 1 || json['isOnline'] == true,
      rating: SafeConvert.toDouble(json['rating'], 5.0),
      totalDeliveries: SafeConvert.toInt(json['totalDeliveries'] ?? json['total_deliveries']),
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
    );
  }
}
