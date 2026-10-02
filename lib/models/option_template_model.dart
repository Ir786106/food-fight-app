import '../core/utils/safe_convert.dart';

/// Single item within a size set or extras template (e.g. 'Large' or 'Extra Cheese' Rs. 150)
class OptionTemplateItem {
  final String id;
  final String name;
  final double price; // Flat price or price delta
  final bool isDefault;

  const OptionTemplateItem({
    required this.id,
    required this.name,
    required this.price,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'isDefault': isDefault,
      };

  factory OptionTemplateItem.fromJson(Map<String, dynamic> json) {
    return OptionTemplateItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: SafeConvert.toDouble(json['price']),
      isDefault: json['isDefault'] == true || json['isDefault'] == 1,
    );
  }
}

/// Reusable Option Template (Size Set or Extras Group)
class OptionTemplateModel {
  final String id;
  final String name; // e.g. "4 Sizes (S, M, L, XL)" or "Extra Toppings" or "Dip Sauces"
  final String type; // 'size_set' or 'extras_group'
  final List<OptionTemplateItem> items;
  final int minSelections;
  final int maxSelections;
  final bool isRequired;
  final String? branchId; // null or 'all' = global/super admin
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  OptionTemplateModel({
    required this.id,
    required this.name,
    required this.type,
    required this.items,
    this.minSelections = 0,
    this.maxSelections = 1,
    this.isRequired = false,
    this.branchId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSizeSet => type == 'size_set';
  bool get isExtrasGroup => type == 'extras_group';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'items': items.map((i) => i.toJson()).toList(),
        'minSelections': minSelections,
        'maxSelections': maxSelections,
        'isRequired': isRequired,
        'branchId': branchId,
        'isActive': isActive,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory OptionTemplateModel.fromJson(Map<String, dynamic> json) {
    List<OptionTemplateItem> parsedItems = [];
    if (json['items'] is List) {
      parsedItems = (json['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map((i) => OptionTemplateItem.fromJson(i))
          .toList();
    }

    return OptionTemplateModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'size_set',
      items: parsedItems,
      minSelections: SafeConvert.toInt(json['minSelections']),
      maxSelections: SafeConvert.toInt(json['maxSelections'], 1),
      isRequired: json['isRequired'] == true || json['isRequired'] == 1,
      branchId: json['branchId']?.toString(),
      isActive: json['isActive'] == 1 || json['isActive'] == true || json['isActive'] == null,
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      updatedAt: SafeConvert.toDateTime(json['updatedAt']),
    );
  }

  OptionTemplateModel copyWith({
    String? id,
    String? name,
    String? type,
    List<OptionTemplateItem>? items,
    int? minSelections,
    int? maxSelections,
    bool? isRequired,
    String? branchId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OptionTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      items: items ?? this.items,
      minSelections: minSelections ?? this.minSelections,
      maxSelections: maxSelections ?? this.maxSelections,
      isRequired: isRequired ?? this.isRequired,
      branchId: branchId ?? this.branchId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
