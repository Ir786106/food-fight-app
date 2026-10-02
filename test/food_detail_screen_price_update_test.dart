import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/providers/cart_provider.dart';
import 'package:food_fight/providers/review_provider.dart';
import 'package:food_fight/screens/food/food_detail_screen.dart';

void main() {
  group('FoodDetailScreen Price Update & Size Selector Tests', () {
    final foodWithSizes = FoodModel(
      id: 'food-sizes',
      name: 'Fighter Specialty Pizza',
      description: 'Thin crust with premium mozzarella and chicken tikka',
      price: 600,
      imageEmoji: '🍕',
      category: 'Pizza',
      rating: 4.9,
      prepTimeMinutes: 20,
      restaurantId: 'rest-1',
      isAvailable: true,
      variants: [
        const MenuVariant(label: 'Small', price: 600, description: '6 inch personal size'),
        const MenuVariant(label: 'Medium', price: 1100, description: '10 inch sharing size'),
        const MenuVariant(label: 'Large', price: 1600, description: '14 inch family size'),
      ],
    );

    testWidgets('Selecting sizes updates the live unit price and bottom CTA price', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cart = CartProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider<ReviewProvider>.value(value: ReviewProvider()),
          ],
          child: MaterialApp(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                settings: RouteSettings(arguments: foodWithSizes),
                builder: (_) => const FoodDetailScreen(),
              );
            },
          ),
        ),
      );

      // Verify title & initial price for Small (first variant = 600)
      expect(find.text('Fighter Specialty Pizza'), findsAtLeastNWidgets(1));
      expect(find.text('Add to cart · Rs. 600'), findsOneWidget);

      // Verify size buttons (S, M, L)
      expect(find.text('S'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);

      // Tap Medium size (M)
      await tester.tap(find.text('M'));
      await tester.pumpAndSettle();

      // Price updates to Medium price (1100)
      expect(find.text('Add to cart · Rs. 1100'), findsOneWidget);

      // Tap Large size (L)
      await tester.tap(find.text('L'));
      await tester.pumpAndSettle();

      // Price updates to Large price (1600)
      expect(find.text('Add to cart · Rs. 1600'), findsOneWidget);
    });

    testWidgets('Quantity stepper updates bottom CTA price dynamically', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cart = CartProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider<ReviewProvider>.value(value: ReviewProvider()),
          ],
          child: MaterialApp(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                settings: RouteSettings(arguments: foodWithSizes),
                builder: (_) => const FoodDetailScreen(),
              );
            },
          ),
        ),
      );

      // Initially 1x Small = 600
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Add to cart · Rs. 600'), findsOneWidget);

      // Tap plus button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Quantity = 2, Total = 1200
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Add to cart · Rs. 1200'), findsOneWidget);

      // Tap plus button again
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Quantity = 3, Total = 1800
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Add to cart · Rs. 1800'), findsOneWidget);

      // Tap minus button
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      // Quantity = 2, Total = 1200
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Add to cart · Rs. 1200'), findsOneWidget);
    });

    testWidgets('Tapping bottom CTA adds item to cart and dismisses screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cart = CartProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider<ReviewProvider>.value(value: ReviewProvider()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: RouteSettings(arguments: foodWithSizes),
                      builder: (_) => const FoodDetailScreen(),
                    ),
                  );
                },
                child: const Text('Open Detail'),
              ),
            ),
          ),
        ),
      );

      // Open detail
      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();

      expect(find.text('Fighter Specialty Pizza'), findsAtLeastNWidgets(1));
      expect(cart.itemCount, equals(0));

      // Tap Add to Cart bottom pill
      await tester.tap(find.text('Add to cart · Rs. 600'));
      await tester.pumpAndSettle();

      // Screen should pop and item is in cart
      expect(cart.itemCount, equals(1));
      expect(cart.items.first.food.name, equals('Fighter Specialty Pizza'));
    });
  });
}
