import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/providers/cart_provider.dart';
import 'package:food_fight/widgets/home/product_card.dart';
import 'package:food_fight/widgets/menu/item_customization_bottom_sheet.dart';

void main() {
  group('ProductCard Widget & Add-to-Cart Tests', () {
    final simpleFood = FoodModel(
      id: 'food-simple',
      name: 'Classic Burger',
      description: 'Juicy beef patty with fresh cheese',
      price: 450,
      imageEmoji: '🍔',
      category: 'Burgers',
      rating: 4.8,
      prepTimeMinutes: 15,
      restaurantId: 'rest-1',
      isAvailable: true,
      isVeg: false,
    );

    final variantFood = FoodModel(
      id: 'food-variant',
      name: 'Loaded Pizza',
      description: 'Melted cheese and mushrooms',
      price: 900,
      imageEmoji: '🍕',
      category: 'Pizza',
      rating: 4.9,
      prepTimeMinutes: 20,
      restaurantId: 'rest-1',
      isAvailable: true,
      variants: [
        const MenuVariant(label: 'Small', price: 700),
        const MenuVariant(label: 'Medium', price: 1100),
      ],
    );

    final unavailableFood = FoodModel(
      id: 'food-unavail',
      name: 'Special Platter',
      description: 'Limited chef special',
      price: 1500,
      imageEmoji: '🍱',
      category: 'Deals',
      rating: 4.7,
      prepTimeMinutes: 25,
      restaurantId: 'rest-1',
      isAvailable: false,
    );

    testWidgets('Renders name, description, rating, and bold price', (tester) async {
      final cart = CartProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<CartProvider>.value(
          value: cart,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProductCard(
                  food: simpleFood,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Classic Burger'), findsOneWidget);
      expect(find.text('Juicy beef patty with fresh cheese'), findsOneWidget);
      expect(find.text('Rs. 450'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('Tapping yellow add button on item without variants adds directly to cart', (tester) async {
      final cart = CartProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<CartProvider>.value(
          value: cart,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProductCard(
                  food: simpleFood,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(cart.itemCount, equals(0));

      // Tap add button
      await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
      await tester.pumpAndSettle();

      expect(cart.itemCount, equals(1));
      expect(cart.items.first.food.name, equals('Classic Burger'));
    });

    testWidgets('Tapping add button on item with variants opens customization sheet', (tester) async {
      final cart = CartProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<CartProvider>.value(
          value: cart,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProductCard(
                  food: variantFood,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // Tap tune/options button
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Customization bottom sheet should be presented
      expect(find.byType(ItemCustomizationBottomSheet), findsOneWidget);
    });

    testWidgets('Unavailable food item shows chip and disables add action', (tester) async {
      final cart = CartProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<CartProvider>.value(
          value: cart,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProductCard(
                  food: unavailableFood,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Unavailable'), findsOneWidget);
      expect(cart.itemCount, equals(0));

      // Tap disabled button
      await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
      await tester.pumpAndSettle();

      // Cart count remains 0
      expect(cart.itemCount, equals(0));
    });
  });
}
