import 'dart:math' as math;
import '../core/utils/safe_convert.dart';

/// Multi-branch model representing physical restaurant branch locations
class BranchModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final String status; // 'active', 'inactive'
  final double revenue;
  final int orderCount;
  final double expenses;
  final double rating;
  final String? imageUrl;
  final String openingHours;
  final double? latitude;
  final double? longitude;
  final double deliveryRadiusKm;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BranchModel({
    required this.id,
    required this.name,
    required this.address,
    this.city = 'Islamabad',
    required this.phone,
    this.status = 'active',
    this.revenue = 0.0,
    this.orderCount = 0,
    this.expenses = 0.0,
    this.rating = 4.8,
    this.imageUrl,
    this.openingHours = '11:00 AM – 02:00 AM',
    this.latitude,
    this.longitude,
    this.deliveryRadiusKm = 10.0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  double get effectiveRadiusKm => deliveryRadiusKm;

  /// Whether valid coordinates are configured for this branch
  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      !latitude!.isNaN &&
      !longitude!.isNaN &&
      (latitude != 0.0 || longitude != 0.0);

  /// Financial Profit or Loss = Revenue - Expenses
  double get profit => revenue - expenses;

  /// Average order value
  double get averageOrderValue => orderCount > 0 ? (revenue / orderCount) : 0.0;

  /// Compute distance in kilometers using the Haversine formula
  double distanceToKm(double userLat, double userLng) {
    if (!hasCoordinates) return double.infinity;

    const earthRadiusKm = 6371.0;
    final dLat = (userLat - latitude!) * (math.pi / 180.0);
    final dLng = (userLng - longitude!) * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(latitude! * (math.pi / 180.0)) *
            math.cos(userLat * (math.pi / 180.0)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Whether a given point lies within this branch's delivery radius
  bool isWithinDeliveryRadius(double userLat, double userLng) {
    final dist = distanceToKm(userLat, userLng);
    return dist <= deliveryRadiusKm;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'phone': phone,
      'status': status,
      'revenue': revenue,
      'orderCount': orderCount,
      'expenses': expenses,
      'rating': rating,
      'imageUrl': imageUrl,
      'openingHours': openingHours,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'deliveryRadiusKm': deliveryRadiusKm,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    final rawRadius = json['deliveryRadiusKm'] ?? json['deliveryRadius'] ?? json['radiusKm'];
    final parsedRadius = SafeConvert.toDouble(rawRadius, 10.0);

    return BranchModel(
      id: (json['id'] ?? json['uid'] ?? '').toString(),
      name: (json['name'] ?? 'Food Fight Branch').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? 'Islamabad').toString(),
      phone: (json['phone'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      revenue: SafeConvert.toDouble(json['revenue']),
      orderCount: SafeConvert.toInt(json['orderCount'] ?? json['ordersCount'], 0),
      expenses: SafeConvert.toDouble(json['expenses']),
      rating: SafeConvert.toDouble(json['rating'], 4.8),
      imageUrl: json['imageUrl']?.toString(),
      openingHours: (json['openingHours'] ?? '11:00 AM – 02:00 AM').toString(),
      latitude: json['latitude'] != null ? SafeConvert.toDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? SafeConvert.toDouble(json['longitude']) : null,
      deliveryRadiusKm: parsedRadius > 0 ? parsedRadius : 10.0,
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
    );
  }

  BranchModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? phone,
    String? status,
    double? revenue,
    int? orderCount,
    double? expenses,
    double? rating,
    String? imageUrl,
    String? openingHours,
    double? latitude,
    double? longitude,
    double? deliveryRadiusKm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BranchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      revenue: revenue ?? this.revenue,
      orderCount: orderCount ?? this.orderCount,
      expenses: expenses ?? this.expenses,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      openingHours: openingHours ?? this.openingHours,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deliveryRadiusKm: deliveryRadiusKm ?? this.deliveryRadiusKm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
