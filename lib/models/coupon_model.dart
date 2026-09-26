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
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      type: json['type'] ?? 'percentage',
      value: (json['value'] ?? 0).toDouble(),
      minimumOrder: (json['minimumOrder'] ?? 0).toDouble(),
      maximumDiscount: json['maximumDiscount'] != null ? (json['maximumDiscount'] as num).toDouble() : null,
      validFrom: DateTime.fromMillisecondsSinceEpoch(json['validFrom'] ?? 0),
      validUntil: DateTime.fromMillisecondsSinceEpoch(json['validUntil'] ?? 0),
      usageLimit: json['usageLimit'] ?? 0,
      usageCount: json['usageCount'] ?? 0,
      isActive: json['isActive'] == 1 || json['isActive'] == true,
      description: json['description'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
    );
  }
}
