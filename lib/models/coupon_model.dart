import '../core/utils/safe_convert.dart';

class CouponModel {
  final String id;
  final String code;
  final String type;
  final double value;
  final double minimumOrder;
  final double? maximumDiscount;
  final DateTime validFrom;
  final DateTime validUntil;
  final int usageLimit;
  final int usageCount;
  final bool isActive;
  final String? description;
  final String? branchId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CouponModel({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minimumOrder = 0,
    this.maximumDiscount,
    required this.validFrom,
    required this.validUntil,
    this.usageLimit = 0,
    this.usageCount = 0,
    this.isActive = true,
    this.description,
    this.branchId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'value': value,
      'minimumOrder': minimumOrder,
      'maximumDiscount': maximumDiscount,
      'validFrom': validFrom.millisecondsSinceEpoch,
      'validUntil': validUntil.millisecondsSinceEpoch,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'isActive': isActive ? 1 : 0,
      'description': description,
      if (branchId != null) 'branchId': branchId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      type: json['type']?.toString() ?? 'percentage',
      value: SafeConvert.toDouble(json['value']),
      minimumOrder: SafeConvert.toDouble(json['minimumOrder']),
      maximumDiscount: json['maximumDiscount'] != null ? SafeConvert.toDouble(json['maximumDiscount']) : null,
      validFrom: SafeConvert.toDateTime(json['validFrom']),
      validUntil: SafeConvert.toDateTime(json['validUntil']),
      usageLimit: SafeConvert.toInt(json['usageLimit']),
      usageCount: SafeConvert.toInt(json['usageCount']),
      isActive: json['isActive'] == 1 || json['isActive'] == true,
      description: json['description']?.toString(),
      branchId: json['branchId']?.toString() ?? json['branch_id']?.toString(),
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
    );
  }
}
