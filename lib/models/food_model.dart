import 'menu_item_model.dart';

class FoodModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<MenuVariant>? variants;
  final List<MenuAddon>? addons;
  final Map<String, double>? sizePrices;
  final String imageEmoji;
  final String? imageUrl;
  final String category;
  final double rating;
  final int prepTimeMinutes;
  final String restaurantId;
  final bool isSpicy;
  final bool isVeg;

  FoodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.variants,
    this.addons,
    this.sizePrices,
    this.imageEmoji = '🥊',
    this.imageUrl,
    required this.category,
    this.rating = 4.8,
    this.prepTimeMinutes = 25,
    this.restaurantId = 'food_fight_hq',
    this.isSpicy = false,
    this.isVeg = true,
  });

  /// True if item has selectable size or portion variants
  bool get hasVariants =>
      (variants != null && variants!.isNotEmpty) ||
      (sizePrices != null && sizePrices!.isNotEmpty);

  /// True if item has optional add-ons/extras
  bool get hasAddons => addons != null && addons!.isNotEmpty;

  /// Returns effective price for a given variant label or size
  double priceForSize(String? selectedSize) {
    if (variants != null && variants!.isNotEmpty && selectedSize != null) {
      final match = variants!.firstWhere(
        (v) => v.label.toLowerCase() == selectedSize.toLowerCase(),
        orElse: () => variants!.first,
      );
      return match.finalPrice;
    }
    if (sizePrices != null && selectedSize != null && sizePrices!.containsKey(selectedSize)) {
      return sizePrices![selectedSize]!;
    }
    return price > 0 ? price : startingPrice;
  }

  /// Starting / lowest available price
  double get startingPrice {
    if (variants != null && variants!.isNotEmpty) {
      return variants!
          .map((v) => v.finalPrice)
          .reduce((a, b) => a < b ? a : b);
    }
    if (sizePrices != null && sizePrices!.isNotEmpty) {
      return sizePrices!.values.reduce((minValue, current) => current < minValue ? current : minValue);
    }
    return price;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'variants': variants?.map((v) => v.toJson()).toList(),
      'addons': addons?.map((a) => a.toJson()).toList(),
      'sizePrices': sizePrices,
      'imageEmoji': imageEmoji,
      'imageUrl': imageUrl,
      'category': category,
      'rating': rating,
      'prepTimeMinutes': prepTimeMinutes,
      'restaurantId': restaurantId,
      'isSpicy': isSpicy,
      'isVeg': isVeg,
    };
  }

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    // Parse variants
    List<MenuVariant>? parsedVariants;
    if (json['variants'] is List) {
      parsedVariants = (json['variants'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => MenuVariant.fromJson(v))
          .toList();
    } else if (json['sizePrices'] != null && json['sizePrices'] is Map) {
      final sizeMap = Map<String, dynamic>.from(json['sizePrices'] as Map);
      parsedVariants = sizeMap.entries.map((e) {
        return MenuVariant(
          label: e.key.toString(),
          price: (e.value is num) ? (e.value as num).toDouble() : 0.0,
        );
      }).toList();
    }

    // Parse addons
    List<MenuAddon>? parsedAddons;
    if (json['addons'] is List) {
      parsedAddons = (json['addons'] as List)
          .whereType<Map<String, dynamic>>()
          .map((a) => MenuAddon.fromJson(a))
          .toList();
    }

    return FoodModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      variants: parsedVariants,
      addons: parsedAddons,
      sizePrices: json['sizePrices'] != null ? Map<String, double>.from(json['sizePrices']) : null,
      imageEmoji: json['imageEmoji'] ?? '🥊',
      imageUrl: json['imageUrl'],
      category: json['category'] ?? '',
      rating: (json['rating'] ?? 4.8).toDouble(),
      prepTimeMinutes: json['prepTimeMinutes'] ?? 25,
      restaurantId: json['restaurantId'] ?? 'food_fight_hq',
      isSpicy: json['isSpicy'] ?? false,
      isVeg: json['isVeg'] ?? true,
    );
  }

  factory FoodModel.fromMenuItem(MenuItemModel item, {String categoryName = ''}) {
    return FoodModel(
      id: item.id,
      name: item.name,
      description: item.description,
      price: item.finalPrice > 0 ? item.finalPrice : item.price,
      variants: item.variants,
      addons: item.addons,
      sizePrices: item.sizePrices,
      imageEmoji: '🥊',
      imageUrl: item.imageUrl,
      category: categoryName.isNotEmpty ? categoryName : item.categoryId,
      rating: item.rating > 0 ? item.rating : 4.8,
      prepTimeMinutes: item.prepTimeMinutes,
      restaurantId: item.restaurantId ?? 'food_fight_hq',
      isSpicy: item.isSpicy,
      isVeg: item.isVeg,
    );
  }
}
