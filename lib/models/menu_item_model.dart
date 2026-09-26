/// Model for a size or portion variant (e.g. Small, Medium, Large, Quarter, Half, 5 Pcs)
class MenuVariant {
  final String label;
  final double price;
  final double discount;
  final String? description;

  const MenuVariant({
    required this.label,
    required this.price,
    this.discount = 0,
    this.description,
  });

  /// Price after applying discount (if any)
  double get finalPrice {
    if (discount <= 0) return price;
    final discounted = price - (price * discount / 100.0);
    return discounted > 0 ? discounted : 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'price': price,
      'discount': discount,
      'description': description,
    };
  }

  factory MenuVariant.fromJson(Map<String, dynamic> json) {
    return MenuVariant(
      label: (json['label'] ?? '').toString(),
      price: (json['price'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      description: json['description']?.toString(),
    );
  }

  MenuVariant copyWith({
    String? label,
    double? price,
    double? discount,
    String? description,
  }) {
    return MenuVariant(
      label: label ?? this.label,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      description: description ?? this.description,
    );
  }
}

/// Model for an optional extra / add-on (e.g. Extra Cheese, Dip Sauce, Extra Chicken)
class MenuAddon {
  final String name;
  final double price;

  const MenuAddon({
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }

  factory MenuAddon.fromJson(Map<String, dynamic> json) {
    return MenuAddon(
      name: (json['name'] ?? '').toString(),
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  MenuAddon copyWith({
    String? name,
    double? price,
  }) {
    return MenuAddon(
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }
}

/// Complete Menu Item Model supporting single flat price OR multi-size variants and extras
class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double discount;
  final double finalPrice;
  final String? imageUrl;
  final String categoryId;
  final String? restaurantId;
  final bool isActive;
  final bool isFeatured;
  final bool isVeg;
  final bool isSpicy;
  final int prepTimeMinutes;
  final double rating;
  final List<MenuVariant>? variants;
  final List<MenuAddon>? addons;
  final Map<String, double>? sizePrices;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discount = 0,
    this.finalPrice = 0,
    this.imageUrl,
    required this.categoryId,
    this.restaurantId,
    this.isActive = true,
    this.isFeatured = false,
    this.isVeg = true,
    this.isSpicy = false,
    this.prepTimeMinutes = 30,
    this.rating = 0,
    this.variants,
    this.addons,
    this.sizePrices,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True if item has at least one selectable size/portion variant
  bool get hasVariants => variants != null && variants!.isNotEmpty;

  /// True if item has optional extras/add-ons
  bool get hasAddons => addons != null && addons!.isNotEmpty;

  /// Compatibility getter for popular/featured status
  bool get isPopular => isFeatured || rating >= 4.5;

  /// Lowest price among variants (or base final price if flat)
  double get minPrice {
    if (hasVariants) {
      return variants!
          .map((v) => v.finalPrice)
          .reduce((a, b) => a < b ? a : b);
    }
    return finalPrice > 0 ? finalPrice : price;
  }

  /// Highest price among variants (or base final price if flat)
  double get maxPrice {
    if (hasVariants) {
      return variants!
          .map((v) => v.finalPrice)
          .reduce((a, b) => a > b ? a : b);
    }
    return finalPrice > 0 ? finalPrice : price;
  }

  /// Formatted price or price range string
  String get formattedPriceRange {
    if (hasVariants) {
      final min = minPrice;
      final max = maxPrice;
      if ((min - max).abs() < 0.01) {
        return 'Rs. ${min.toStringAsFixed(0)}';
      }
      return 'Rs. ${min.toStringAsFixed(0)} – Rs. ${max.toStringAsFixed(0)}';
    }
    final p = finalPrice > 0 ? finalPrice : price;
    return 'Rs. ${p.toStringAsFixed(0)}';
  }

  Map<String, dynamic> toJson() {
    // Generate legacy sizePrices map for backwards compatibility
    Map<String, double>? legacySizes = sizePrices;
    if (variants != null && variants!.isNotEmpty) {
      legacySizes = {for (var v in variants!) v.label: v.price};
    }

    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discount': discount,
      'finalPrice': finalPrice,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'restaurantId': restaurantId,
      'isActive': isActive ? 1 : 0,
      'isFeatured': isFeatured ? 1 : 0,
      'isVeg': isVeg ? 1 : 0,
      'isSpicy': isSpicy ? 1 : 0,
      'prepTimeMinutes': prepTimeMinutes,
      'rating': rating,
      'variants': variants?.map((v) => v.toJson()).toList(),
      'addons': addons?.map((a) => a.toJson()).toList(),
      'sizePrices': legacySizes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    // Parse variants if available
    List<MenuVariant>? parsedVariants;
    if (json['variants'] is List) {
      parsedVariants = (json['variants'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => MenuVariant.fromJson(v))
          .toList();
    } else if (json['sizePrices'] != null && json['sizePrices'] is Map) {
      // Automatic backward-compatible migration from legacy sizePrices
      final sizeMap = Map<String, dynamic>.from(json['sizePrices'] as Map);
      parsedVariants = sizeMap.entries.map((e) {
        return MenuVariant(
          label: e.key.toString(),
          price: (e.value is num) ? (e.value as num).toDouble() : 0.0,
        );
      }).toList();
    }

    // Parse addons if available
    List<MenuAddon>? parsedAddons;
    if (json['addons'] is List) {
      parsedAddons = (json['addons'] as List)
          .whereType<Map<String, dynamic>>()
          .map((a) => MenuAddon.fromJson(a))
          .toList();
    }

    return MenuItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      finalPrice: (json['finalPrice'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? json['image_url'],
      categoryId: json['categoryId'] ?? json['category_id'] ?? '',
      restaurantId: json['restaurantId'] ?? json['restaurant_id'],
      isActive: json['isActive'] == 1 || json['isActive'] == true,
      isFeatured: json['isFeatured'] == 1 || json['isFeatured'] == true,
      isVeg: json['isVeg'] == 1 || json['isVeg'] == true,
      isSpicy: json['isSpicy'] == 1 || json['isSpicy'] == true,
      prepTimeMinutes: json['prepTimeMinutes'] ?? json['prep_time_minutes'] ?? 30,
      rating: (json['rating'] ?? 0).toDouble(),
      variants: parsedVariants,
      addons: parsedAddons,
      sizePrices: json['sizePrices'] != null && json['sizePrices'] is Map
          ? Map<String, double>.from(
              (json['sizePrices'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())))
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
    );
  }

  MenuItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discount,
    double? finalPrice,
    String? imageUrl,
    String? categoryId,
    String? restaurantId,
    bool? isActive,
    bool? isFeatured,
    bool? isVeg,
    bool? isSpicy,
    int? prepTimeMinutes,
    double? rating,
    List<MenuVariant>? variants,
    List<MenuAddon>? addons,
    Map<String, double>? sizePrices,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      finalPrice: finalPrice ?? this.finalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      restaurantId: restaurantId ?? this.restaurantId,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isVeg: isVeg ?? this.isVeg,
      isSpicy: isSpicy ?? this.isSpicy,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      rating: rating ?? this.rating,
      variants: variants ?? this.variants,
      addons: addons ?? this.addons,
      sizePrices: sizePrices ?? this.sizePrices,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
