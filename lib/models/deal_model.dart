import '../core/utils/safe_convert.dart';

/// Bundle item definition included in a Deal
class DealBundleItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final String? size;

  const DealBundleItem({
    required this.menuItemId,
    required this.name,
    this.quantity = 1,
    this.size,
  });

  Map<String, dynamic> toJson() => {
        'menuItemId': menuItemId,
        'name': name,
        'quantity': quantity,
        if (size != null) 'size': size,
      };

  factory DealBundleItem.fromJson(Map<String, dynamic> json) {
    return DealBundleItem(
      menuItemId: json['menuItemId']?.toString() ?? json['itemId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: SafeConvert.toInt(json['quantity'], 1),
      size: json['size']?.toString(),
    );
  }
}

/// Deal model for restaurant promotions, combos and special branch offers
class DealModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final double dealPrice;
  final double originalPrice;
  final double? discountPercentage;
  final String discountType; // 'fixed_price', 'percentage', 'bundle'
  final List<String> linkedItemIds;
  final List<DealBundleItem> bundleItems;
  final String? branchId;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int> activeDays; // 1 = Monday, 7 = Sunday
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DealModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.dealPrice,
    this.originalPrice = 0.0,
    this.discountPercentage,
    this.discountType = 'fixed_price',
    List<String>? linkedItemIds,
    List<DealBundleItem>? bundleItems,
    this.branchId,
    this.startDate,
    this.endDate,
    List<int>? activeDays,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  })  : linkedItemIds = linkedItemIds ?? [],
        bundleItems = bundleItems ?? [],
        activeDays = activeDays ?? const [1, 2, 3, 4, 5, 6, 7];

  /// Checks if the deal is currently valid (date range, active flag, day of week)
  bool get isValidNow {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    if (activeDays.isNotEmpty && !activeDays.contains(now.weekday)) return false;
    return true;
  }

  /// Savings percentage
  double get savingsPercentage {
    if (originalPrice <= 0 || dealPrice >= originalPrice) {
      return discountPercentage ?? 0.0;
    }
    return (((originalPrice - dealPrice) / originalPrice) * 100).clamp(0, 100);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'dealPrice': dealPrice,
        'originalPrice': originalPrice,
        'discountPercentage': discountPercentage,
        'discountType': discountType,
        'linkedItemIds': linkedItemIds,
        'bundleItems': bundleItems.map((b) => b.toJson()).toList(),
        'branchId': branchId,
        'startDate': startDate?.millisecondsSinceEpoch,
        'endDate': endDate?.millisecondsSinceEpoch,
        'activeDays': activeDays,
        'isActive': isActive,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory DealModel.fromJson(Map<String, dynamic> json) {
    List<DealBundleItem> parsedBundle = [];
    if (json['bundleItems'] is List) {
      parsedBundle = (json['bundleItems'] as List)
          .whereType<Map<String, dynamic>>()
          .map((b) => DealBundleItem.fromJson(b))
          .toList();
    }

    List<String> parsedLinked = [];
    if (json['linkedItemIds'] is List) {
      parsedLinked = (json['linkedItemIds'] as List).map((e) => e.toString()).toList();
    }

    List<int> parsedDays = const [1, 2, 3, 4, 5, 6, 7];
    if (json['activeDays'] is List) {
      parsedDays = (json['activeDays'] as List).map((e) => SafeConvert.toInt(e, 1)).toList();
    }

    return DealModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      dealPrice: SafeConvert.toDouble(json['dealPrice'] ?? json['price']),
      originalPrice: SafeConvert.toDouble(json['originalPrice'] ?? json['original_price']),
      discountPercentage: json['discountPercentage'] != null
          ? SafeConvert.toDouble(json['discountPercentage'])
          : null,
      discountType: json['discountType']?.toString() ?? 'fixed_price',
      linkedItemIds: parsedLinked,
      bundleItems: parsedBundle,
      branchId: json['branchId']?.toString(),
      startDate: json['startDate'] != null ? SafeConvert.toDateTime(json['startDate']) : null,
      endDate: json['endDate'] != null ? SafeConvert.toDateTime(json['endDate']) : null,
      activeDays: parsedDays,
      isActive: json['isActive'] == 1 || json['isActive'] == true || json['isActive'] == null,
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
    );
  }

  DealModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    double? dealPrice,
    double? originalPrice,
    double? discountPercentage,
    String? discountType,
    List<String>? linkedItemIds,
    List<DealBundleItem>? bundleItems,
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? activeDays,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DealModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      dealPrice: dealPrice ?? this.dealPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountType: discountType ?? this.discountType,
      linkedItemIds: linkedItemIds ?? this.linkedItemIds,
      bundleItems: bundleItems ?? this.bundleItems,
      branchId: branchId ?? this.branchId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      activeDays: activeDays ?? this.activeDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
