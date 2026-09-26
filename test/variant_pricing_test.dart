import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/models/cart_item_model.dart';

void main() {
  group('Multi-Size Variant & Extras Data Model Tests', () {
    test('MenuItemModel calculates price range and variant status correctly', () {
      final pizza = MenuItemModel(
        id: 'pizza_1',
        name: 'Chicken Tikka Pizza',
        description: 'Tikka Topping + Onion + Black Olives',
        price: 399,
        categoryId: 'cat_pizza',
        variants: [
          const MenuVariant(label: 'Small', price: 399),
          const MenuVariant(label: 'Medium', price: 799),
          const MenuVariant(label: 'Large', price: 1199, discount: 10), // 1079.1
          const MenuVariant(label: 'XL', price: 1599),
        ],
        addons: [
          const MenuAddon(name: 'Extra Cheese', price: 200),
          const MenuAddon(name: 'Dip Sauce', price: 70),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(pizza.hasVariants, isTrue);
      expect(pizza.hasAddons, isTrue);
      expect(pizza.minPrice, 399);
      expect(pizza.maxPrice, 1599);
      expect(pizza.formattedPriceRange, 'Rs. 399 – Rs. 1599');

      // Test JSON round-trip
      final json = pizza.toJson();
      expect(json['variants'], isNotNull);
      expect(json['addons'], isNotNull);
      expect(json['sizePrices'], isNotNull); // Legacy compatibility

      final restored = MenuItemModel.fromJson(json);
      expect(restored.hasVariants, isTrue);
      expect(restored.variants!.length, 4);
      expect(restored.addons!.length, 2);
      expect(restored.variants![2].discount, 10);
    });

    test('Backward compatibility: legacy sizePrices map converts to variants', () {
      final legacyJson = {
        'id': 'legacy_item',
        'name': 'Legacy Pizza',
        'description': 'Delicious legacy',
        'price': 400,
        'categoryId': 'cat_1',
        'sizePrices': {'Small': 400.0, 'Medium': 800.0, 'Large': 1200.0},
        'createdAt': 1600000000000,
        'updatedAt': 1600000000000,
      };

      final item = MenuItemModel.fromJson(legacyJson);
      expect(item.hasVariants, isTrue);
      expect(item.variants!.length, 3);
      expect(item.variants!.first.label, 'Small');
      expect(item.variants!.first.price, 400.0);
      expect(item.minPrice, 400.0);
      expect(item.maxPrice, 1200.0);
    });

    test('Single flat-price item without variants works backward-compatibly', () {
      final burger = MenuItemModel(
        id: 'burger_1',
        name: 'Zinger Burger',
        description: 'Crispy burger with fries',
        price: 349,
        discount: 0,
        finalPrice: 349,
        categoryId: 'cat_burgers',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(burger.hasVariants, isFalse);
      expect(burger.hasAddons, isFalse);
      expect(burger.minPrice, 349);
      expect(burger.maxPrice, 349);
      expect(burger.formattedPriceRange, 'Rs. 349');
    });

    test('FoodModel accurately reflects startingPrice across variants and fallback', () {
      final foodWithVariants = FoodModel(
        id: 'f1',
        name: 'Broast',
        description: 'Crispy broast',
        price: 399,
        category: 'Broast',
        variants: [
          const MenuVariant(label: 'Quarter', price: 399),
          const MenuVariant(label: 'Half', price: 749),
          const MenuVariant(label: 'Full', price: 1399),
        ],
      );

      expect(foodWithVariants.hasVariants, isTrue);
      expect(foodWithVariants.startingPrice, 399);
      expect(foodWithVariants.priceForSize('Half'), 749);
      expect(foodWithVariants.priceForSize('Full'), 1399);

      final foodFlat = FoodModel(
        id: 'f2',
        name: 'French Fries',
        description: 'Golden fries',
        price: 180,
        category: 'Fries',
      );

      expect(foodFlat.hasVariants, isFalse);
      expect(foodFlat.startingPrice, 180);
    });
  });

  group('CartItemModel & Line Pricing Tests', () {
    test('Calculates unit price and total price accurately with variants and addons', () {
      final food = FoodModel(
        id: 'pizza_tikka',
        name: 'Chicken Tikka',
        description: 'Tikka pizza',
        price: 399,
        category: 'Pizza',
        variants: [
          const MenuVariant(label: 'Small', price: 399),
          const MenuVariant(label: 'Large', price: 1199),
        ],
        addons: [
          const MenuAddon(name: 'Extra Cheese', price: 200),
          const MenuAddon(name: 'Dip Sauce', price: 70),
        ],
      );

      // 1. Small with no addons, qty = 2
      final line1 = CartItemModel(
        food: food,
        quantity: 2,
        selectedVariant: food.variants![0], // Small 399
      );
      expect(line1.singleUnitPrice, 399);
      expect(line1.totalPrice, 798);
      expect(line1.displayName, 'Chicken Tikka (Small)');
      expect(line1.addonsDescription, isNull);

      // 2. Large with Extra Cheese (200) + Dip Sauce (70), qty = 1
      final line2 = CartItemModel(
        food: food,
        quantity: 1,
        selectedVariant: food.variants![1], // Large 1199
        selectedAddons: [food.addons![0], food.addons![1]], // 200 + 70 = 270
      );
      expect(line2.singleUnitPrice, 1469); // 1199 + 270
      expect(line2.totalPrice, 1469);
      expect(line2.displayName, 'Chicken Tikka (Large)');
      expect(line2.addonsDescription, contains('Extra Cheese'));
      expect(line2.addonsDescription, contains('Dip Sauce'));

      // 3. Different line keys ensuring separate cart lines
      expect(line1.lineKey != line2.lineKey, isTrue);
    });

    test('CartItemModel JSON serializes and restores variant and addons info', () {
      final food = FoodModel(
        id: 'broast_1',
        name: 'Broast',
        description: 'Crispy broast',
        price: 399,
        category: 'Broast',
      );

      final original = CartItemModel(
        food: food,
        quantity: 3,
        selectedVariant: const MenuVariant(
          label: 'Quarter',
          price: 399,
          description: '1 leg, 1 thigh, 1 bun',
        ),
        selectedAddons: [
          const MenuAddon(name: 'Extra Garlic Dip', price: 70),
        ],
      );

      final json = original.toJson();
      expect(json['selectedVariant'], isNotNull);
      expect(json['selectedAddons'], isNotNull);
      expect(json['displayName'], 'Broast (Quarter)');

      final restored = CartItemModel.fromJson(json);
      expect(restored.displayName, 'Broast (Quarter)');
      expect(restored.selectedVariant?.label, 'Quarter');
      expect(restored.selectedAddons.length, 1);
      expect(restored.selectedAddons.first.name, 'Extra Garlic Dip');
      expect(restored.totalPrice, (399 + 70) * 3);
    });
  });
}
