import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:food_fight/main.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/providers/cart_provider.dart';
import 'package:food_fight/services/auth_service.dart';
import 'package:food_fight/widgets/food_card.dart';

void main() {
  testWidgets('FoodFight app builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodFightApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('FoodCard should not produce a right overflow in a narrow layout', (tester) async {
    final food = FoodModel(
      id: 'food-1',
      name: 'Chicken Supreme Spicy Pizza',
      description: 'Chicken tikka, cheese and hot sauce',
      price: 399,
      imageEmoji: '🍕',
      category: 'Pizza',
      rating: 4.8,
      prepTimeMinutes: 20,
      restaurantId: 'rest-1',
      isSpicy: true,
      isVeg: false,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<CartProvider>(
        create: (_) => CartProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: FoodCard(food: food, onTap: () {}),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  test('AuthService allows user signup and subsequent login', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService();

    final signUpError = await auth.signUp(
      name: 'Test Customer',
      email: 'customer@foodfight.test',
      phone: '+923001234567',
      password: 'SecurePassword123!',
    );

    expect(signUpError, isNull);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.currentUser?.email, 'customer@foodfight.test');

    await auth.logout();
    expect(auth.isLoggedIn, isFalse);

    final loginError = await auth.login(
      email: 'customer@foodfight.test',
      password: 'SecurePassword123!',
    );

    expect(loginError, isNull);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.currentUser?.name, 'Test Customer');
  });
}
