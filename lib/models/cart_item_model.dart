import 'food_model.dart';
import 'menu_item_model.dart';

class CartItemModel {
  final FoodModel food;
  int quantity;
  String? note;
  String? selectedSize;
  MenuVariant? selectedVariant;
  List<MenuAddon> selectedAddons;
  final double? unitPrice;

  CartItemModel({
    required this.food,
    this.quantity = 1,
    this.note,
    this.selectedSize,
    this.selectedVariant,
    List<MenuAddon>? selectedAddons,
    this.unitPrice,
  }) : selectedAddons = selectedAddons ?? [];

  /// Unique key distinguishing this line item (differentiating variants & extras)
  String get lineKey {
    final v = selectedVariant?.label ?? selectedSize ?? '';
    final aList = selectedAddons.map((a) => a.name).toList()..sort();
    return '${food.id}::$v::${aList.join(',')}';
  }

  /// Price of a single item including chosen variant and extras
  double get singleUnitPrice {
    if (unitPrice != null && unitPrice! > 0) return unitPrice!;
    final basePrice = selectedVariant != null
        ? selectedVariant!.finalPrice
        : food.priceForSize(selectedSize);
    final addonsTotal = selectedAddons.fold(0.0, (sum, a) => sum + a.price);
    final calculated = basePrice + addonsTotal;
    if (calculated > 0) return calculated;
    return food.startingPrice > 0 ? food.startingPrice : food.price;
  }

  /// Total price for this cart line
  double get totalPrice => singleUnitPrice * quantity;

  /// User-facing item title (e.g. "Chicken Tikka (Large)")
  String get displayName {
    final size = selectedVariant?.label ?? selectedSize;
    if (size != null && size.isNotEmpty) {
      return '${food.name} ($size)';
    }
    return food.name;
  }

  /// Formatted list of selected extras (e.g. "+ Extra Cheese (Rs. 200), Extra Dip (Rs. 70)")
  String? get addonsDescription {
    if (selectedAddons.isEmpty) return null;
    return selectedAddons
        .map((a) => '+ ${a.name} (Rs. ${a.price.toStringAsFixed(0)})')
        .join(', ');
  }

  Map<String, dynamic> toJson() {
    final effectiveSize = selectedVariant?.label ?? selectedSize;
    return {
      'food': food.toJson(),
      'quantity': quantity,
      'note': note,
      'selectedSize': effectiveSize,
      'selectedVariant': selectedVariant?.toJson(),
      'selectedAddons': selectedAddons.map((a) => a.toJson()).toList(),
      'unitPrice': singleUnitPrice,
      'totalPrice': totalPrice,
      'displayName': displayName,
      'addonsDescription': addonsDescription,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final food = FoodModel.fromJson(json['food'] as Map<String, dynamic>);
    final rawSize = json['selectedSize']?.toString();

    // Parse selected variant if saved or resolve from size
    MenuVariant? parsedVariant;
    if (json['selectedVariant'] != null && json['selectedVariant'] is Map) {
      parsedVariant = MenuVariant.fromJson(json['selectedVariant'] as Map<String, dynamic>);
    } else if (rawSize != null && food.variants != null && food.variants!.isNotEmpty) {
      parsedVariant = food.variants!.firstWhere(
        (v) => v.label.toLowerCase() == rawSize.toLowerCase(),
        orElse: () => food.variants!.first,
      );
    }

    // Parse selected addons if saved
    List<MenuAddon> parsedAddons = [];
    if (json['selectedAddons'] is List) {
      parsedAddons = (json['selectedAddons'] as List)
          .whereType<Map<String, dynamic>>()
          .map((a) => MenuAddon.fromJson(a))
          .toList();
    }

    return CartItemModel(
      food: food,
      quantity: json['quantity'] ?? 1,
      note: json['note'],
      selectedSize: rawSize,
      selectedVariant: parsedVariant,
      selectedAddons: parsedAddons,
      unitPrice: json['unitPrice'] != null ? (json['unitPrice'] as num).toDouble() : null,
    );
  }

  CartItemModel copyWith({
    int? quantity,
    String? note,
    String? selectedSize,
    MenuVariant? selectedVariant,
    List<MenuAddon>? selectedAddons,
    double? unitPrice,
  }) {
    return CartItemModel(
      food: food,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      selectedAddons: selectedAddons ?? this.selectedAddons,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}
