import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:food_fight/main.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/routes/role_router.dart';
import 'package:food_fight/providers/cart_provider.dart';
import 'package:food_fight/widgets/food_card.dart';

void main() {
  testWidgets('FoodFight app builds smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FoodFightApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 500));
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

  test('UserRole parsing and RoleRouter routing tests', () {
    expect(UserRole.fromString('superadmin'), UserRole.superAdmin);
    expect(UserRole.fromString('super_admin'), UserRole.superAdmin);
    expect(UserRole.fromString('Super Admin'), UserRole.superAdmin);
    expect(UserRole.fromString('admin'), UserRole.admin);
    expect(UserRole.fromString('branch_admin'), UserRole.admin);
    expect(UserRole.fromString('sub_admin'), UserRole.subAdmin);
    expect(UserRole.fromString('delivery_rider'), UserRole.rider);
    expect(UserRole.fromString('rider'), UserRole.rider);
    expect(UserRole.fromString('customer'), UserRole.customer);
    expect(UserRole.fromString(null), UserRole.customer);

    expect(RoleRouter.homeRouteForRole('super_admin'), '/super-admin/dashboard');
    expect(RoleRouter.homeRouteForRole('admin'), '/admin/dashboard');
    expect(RoleRouter.homeRouteForRole('delivery_rider'), '/rider/dashboard');
    expect(RoleRouter.homeRouteForRole('customer'), '/home');

    // Safe UserModel isActive deserialization (missing isActive = true)
    final userWithNoIsActive = UserModel.fromJson({
      'id': 'u1',
      'name': 'Test',
      'email': 'test@foodfight.test',
      'role': 'super_admin',
    });
    expect(userWithNoIsActive.isActive, isTrue);
    expect(userWithNoIsActive.isSuperAdmin, isTrue);
  });
}
