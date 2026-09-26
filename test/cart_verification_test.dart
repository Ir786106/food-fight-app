import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/models/delivery_area_model.dart';
import 'package:food_fight/providers/cart_provider.dart';
import 'package:food_fight/screens/cart/cart_screen.dart';

void main() {
  group('Cart Comprehensive Audit & Calculations Test', () {
    late CartProvider cart;

    final foodA = FoodModel(
      id: 'food-a',
      name: 'Fight Zinger Burger',
      description: 'Crispy chicken fillet with secret mayo sauce',
      price: 450.0,
      category: 'Burgers',
      rating: 4.8,
      prepTimeMinutes: 15,
      restaurantId: 'rest-1',
    );

    final foodB = FoodModel(
      id: 'food-b',
      name: 'Crown Crust Pizza',
      description: 'Stuffed crust pizza with creamy cheese',
      price: 850.0,
      category: 'Pizza',
      rating: 4.9,
      prepTimeMinutes: 25,
      restaurantId: 'rest-1',
      variants: [
        MenuVariant(label: 'Small', price: 550.0),
        MenuVariant(label: 'Medium', price: 850.0),
        MenuVariant(label: 'Large', price: 1250.0),
      ],
    );

    final foodC = FoodModel(
      id: 'food-c',
      name: 'Broast Crunch',
      description: 'Golden fried chicken portion',
      price: 300.0,
      category: 'Chicken',
      rating: 4.7,
      prepTimeMinutes: 20,
      restaurantId: 'rest-1',
      variants: [
        MenuVariant(label: 'Quarter', price: 300.0),
        MenuVariant(label: 'Half', price: 580.0),
        MenuVariant(label: 'Full', price: 1100.0),
      ],
    );

    setUp(() {
      cart = CartProvider();
    });

    test('1. Initial cart state is empty with 0 badge and 0 totals', () {
      expect(cart.items.isEmpty, true);
      expect(cart.itemCount, 0);
      expect(cart.subtotal, 0.0);
      expect(cart.deliveryFee, 0.0);
      expect(cart.total, 0.0);
    });

    test('2. Add Product A x 1 (flat price)', () {
      cart.addToCart(foodA);
      expect(cart.items.length, 1);
      expect(cart.itemCount, 1);
      expect(cart.items.first.displayName, 'Fight Zinger Burger');
      expect(cart.items.first.singleUnitPrice, 450.0);
      expect(cart.items.first.totalPrice, 450.0);
      expect(cart.subtotal, 450.0);
      expect(cart.deliveryFee, 150.0); // Default delivery charge
      expect(cart.total, 600.0);
    });

    test('3. Add Product B x 1 (variant Medium Rs. 850)', () {
      cart.addToCart(foodA);
      final variantM = foodB.variants![1]; // Medium
      cart.addToCart(foodB, selectedVariant: variantM, selectedSize: 'Medium');

      expect(cart.items.length, 2);
      expect(cart.itemCount, 2);
      expect(cart.subtotal, 450.0 + 850.0);
      expect(cart.total, 1300.0 + 150.0);
    });

    test('4. Add Product A x 1 again -> merges line and updates quantity to 2', () {
      cart.addToCart(foodA);
      final variantM = foodB.variants![1];
      cart.addToCart(foodB, selectedVariant: variantM, selectedSize: 'Medium');
      cart.addToCart(foodA);

      expect(cart.items.length, 2);
      expect(cart.itemCount, 3);
      expect(cart.items.first.quantity, 2);
      expect(cart.items.first.totalPrice, 900.0);
      expect(cart.subtotal, 900.0 + 850.0);
    });

    test('5. Add Product C x 3 (variant Quarter Rs. 300)', () {
      cart.addToCart(foodA); // 1
      final variantM = foodB.variants![1];
      cart.addToCart(foodB, selectedVariant: variantM, selectedSize: 'Medium'); // 1
      cart.addToCart(foodA); // now 2

      final variantQ = foodC.variants![0];
      cart.addToCart(foodC, quantity: 3, selectedVariant: variantQ, selectedSize: 'Quarter');

      expect(cart.items.length, 3);
      expect(cart.itemCount, 6); // 2 + 1 + 3
      expect(cart.subtotal, 900.0 + 850.0 + 900.0); // 2650.0
      expect(cart.total, 2650.0 + 150.0); // 2800.0
    });

    test('6. Increment quantity of Product B', () {
      cart.addToCart(foodA);
      final variantM = foodB.variants![1];
      cart.addToCart(foodB, selectedVariant: variantM, selectedSize: 'Medium');

      final lineKeyB = cart.items.last.lineKey;
      cart.incrementLine(lineKeyB);

      expect(cart.items.last.quantity, 2);
      expect(cart.itemCount, 3); // 1 + 2
      expect(cart.subtotal, 450.0 + 1700.0);
    });

    test('7. Decrement quantity of Product B', () {
      cart.addToCart(foodA);
      final variantM = foodB.variants![1];
      cart.addToCart(foodB, selectedVariant: variantM, selectedSize: 'Medium');

      final lineKeyB = cart.items.last.lineKey;
      cart.incrementLine(lineKeyB); // 2
      cart.decrementLine(lineKeyB); // back to 1

      expect(cart.items.last.quantity, 1);
      expect(cart.itemCount, 2);
      expect(cart.subtotal, 450.0 + 850.0);
    });

    test('8. Remove Product A keeps other products completely unaffected', () {
      cart.addToCart(foodA);
      final variantM = foodB.variants![1];
      cart.addToCart(foodB, selectedVariant: variantM, selectedSize: 'Medium');

      final lineKeyA = cart.items.first.lineKey;
      cart.removeLine(lineKeyA);

      expect(cart.items.length, 1);
      expect(cart.itemCount, 1);
      expect(cart.items.first.food.name, 'Crown Crust Pizza');
      expect(cart.subtotal, 850.0);
    });

    test('9. Set delivery area updates delivery fee and grand total', () {
      cart.addToCart(foodA);
      expect(cart.deliveryFee, 150.0);

      final customArea = DeliveryAreaModel(
        id: 'zone-north',
        name: 'Sector F-11 & E-11',
        deliveryCharge: 220.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      cart.setDeliveryArea(customArea);
      expect(cart.deliveryFee, 220.0);
      expect(cart.total, 450.0 + 220.0);
    });

    test('10. Clear cart clears all items, resets fee to 0 and total to 0', () {
      cart.addToCart(foodA);
      expect(cart.itemCount, 1);
      cart.clearCart();
      expect(cart.items.isEmpty, true);
      expect(cart.itemCount, 0);
      expect(cart.subtotal, 0.0);
      expect(cart.deliveryFee, 0.0);
      expect(cart.total, 0.0);
    });

    test('11. Cart items format correctly for order placement', () {
      cart.addToCart(foodA, quantity: 2);
      expect(cart.items.first.displayName, 'Fight Zinger Burger');
      expect(cart.items.first.quantity, 2);
      expect(cart.items.first.singleUnitPrice, 450.0);
      expect(cart.items.first.totalPrice, 900.0);

      final json = cart.items.first.toJson();
      expect(json['quantity'], 2);
      expect(json['food']['name'], 'Fight Zinger Burger');
    });
  });

  group('Cart Widget Integration & Single Source of Truth Test', () {
    testWidgets('Tapping + adds product and immediately reflects in Cart badge & My Cart', (tester) async {
      final cart = CartProvider();
      final testFood = FoodModel(
        id: 'test-item-1',
        name: 'Smash Double Beef',
        description: 'Two smashed patties with melted cheddar',
        price: 790.0,
        category: 'Burgers',
        rating: 4.9,
        prepTimeMinutes: 15,
        restaurantId: 'rest-1',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<CartProvider>.value(
          value: cart,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final c = context.watch<CartProvider>();
                return Scaffold(
                  body: Center(
                    child: Text('Badge: ${c.itemCount}'),
                  ),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => c.addToCart(testFood),
                    child: const Icon(Icons.add),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify initial empty state
      expect(find.text('Badge: 0'), findsOneWidget);

      // Tap + button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Badge must immediately show 1
      expect(find.text('Badge: 1'), findsOneWidget);

      // Now pump CartScreen using the exact same shared provider
      await tester.pumpWidget(
        ChangeNotifierProvider<CartProvider>.value(
          value: cart,
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Confirm product appears in CartScreen
      expect(find.text('Smash Double Beef'), findsOneWidget);
      expect(find.text('Rs. 790'), findsWidgets);
      expect(find.text('1'), findsOneWidget);

      // Increment quantity in CartScreen
      final plusButton = find.byIcon(Icons.add);
      expect(plusButton, findsOneWidget);
      await tester.tap(plusButton);
      await tester.pumpAndSettle();

      // Quantity should now be 2
      expect(find.text('2'), findsOneWidget);
      expect(cart.itemCount, 2);
      expect(cart.subtotal, 1580.0);
    });
  });
}
