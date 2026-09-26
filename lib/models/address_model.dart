import '../core/utils/safe_convert.dart';

class AddressModel {
  final String id;
  final String userId;
  final String label;
  final String details;
  final String iconType;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.details,
    this.iconType = 'home',
    this.latitude,
    this.longitude,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'details': details,
      'iconType': iconType,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      iconType: json['iconType']?.toString() ?? json['icon_type']?.toString() ?? 'home',
      latitude: json['latitude'] != null ? SafeConvert.toDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? SafeConvert.toDouble(json['longitude']) : null,
      isDefault: json['isDefault'] == 1 || json['isDefault'] == true,
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
    );
  }
}
