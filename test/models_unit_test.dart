import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/branch_model.dart';
import 'package:food_fight/models/cart_item_model.dart';
import 'package:food_fight/models/delivery_area_model.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/models/restaurant_model.dart';
import 'package:food_fight/models/review_model.dart';
import 'package:food_fight/models/rider_model.dart';
import 'package:food_fight/models/user_model.dart';

void main() {
  group('SafeConvert & Model Parsing Tests', () {
    test('MenuItemModel safely parses ints, strings, timestamps without crashing', () {
      final json = {
        'id': 'item-101',
        'name': 'Cheesy Crust Pizza',
        'description': 'Loaded with premium mozzarella and cheddar',
        'price': 1200, // int instead of double
        'discount': 10, // int
        'finalPrice': '1080', // string representation
        'prepTimeMinutes': '25', // string
        'rating': 5, // int
        'sizePrices': {
          'Small': 800,
          'Medium': 1200.5,
          'Large': '1600',
        },
        'createdAt': Timestamp.now(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      final item = MenuItemModel.fromJson(json);
      expect(item.id, 'item-101');
      expect(item.price, 1200.0);
      expect(item.discount, 10.0);
      expect(item.finalPrice, 1080.0);
      expect(item.prepTimeMinutes, 25);
      expect(item.rating, 5.0);
      expect(item.sizePrices?['Small'], 800.0);
      expect(item.sizePrices?['Large'], 1600.0);
    });

    test('FoodModel safely parses legacy sizePrices and variants', () {
      final json = {
        'id': 'food-1',
        'name': 'Gourmet Burger',
        'price': '450',
        'rating': 4,
        'prepTimeMinutes': '15',
        'sizePrices': {
          'Single': 450,
          'Double': 750,
        },
      };

      final food = FoodModel.fromJson(json);
      expect(food.price, 450.0);
      expect(food.rating, 4.0);
      expect(food.prepTimeMinutes, 15);
      expect(food.variants?.length, 2);
      expect(food.variants?.first.label, 'Single');
    });

    test('OrderModel safely parses amounts and timestamps', () {
      final json = {
        'id': 'ord-99',
        'customerId': 'cust-1',
        'branchId': 'branch-1',
        'items': [
          {
            'foodId': 'food-1',
            'name': 'Burger',
            'price': 450,
            'quantity': 2,
            'selectedSize': 'Double',
            'selectedAddons': ['Extra Cheese'],
          }
        ],
        'subtotal': 900,
        'discount': 50,
        'deliveryCharge': 100,
        'total': 950,
        'status': 'placed',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      final order = OrderModel.fromJson(json);
      expect(order.subtotal, 900.0);
      expect(order.discount, 50.0);
      expect(order.deliveryCharge, 100.0);
      expect(order.total, 950.0);
      expect(order.items.length, 1);
      expect(order.items.first.quantity, 2);
    });

    test('BranchModel safely handles financial metrics', () {
      final json = {
        'id': 'b-1',
        'name': 'DHA Phase 5 Branch',
        'address': 'Commercial Area, Phase 5',
        'phone': '+923000000000',
        'city': 'Lahore',
        'revenue': 250000,
        'orderCount': 420,
        'expenses': 120000,
        'rating': 5,
        'createdAt': Timestamp.now(),
      };

      final branch = BranchModel.fromJson(json);
      expect(branch.revenue, 250000.0);
      expect(branch.orderCount, 420);
      expect(branch.expenses, 120000.0);
      expect(branch.rating, 5.0);
    });

    test('UserModel and RiderModel safely parse profile stats', () {
      final riderJson = {
        'id': 'rider-1',
        'name': 'Ali Khan',
        'phone': '+923111111111',
        'rating': 5,
        'totalDeliveries': '150',
        'status': 'available',
      };

      final rider = RiderModel.fromJson(riderJson);
      expect(rider.rating, 5.0);
      expect(rider.totalDeliveries, 150);
      expect(rider.isActive, isTrue);

      final userJson = {
        'id': 'usr-1',
        'name': 'Sara Ahmed',
        'email': 'sara@test.com',
        'phone': '+923222222222',
        'role': 'customer',
        'createdAt': Timestamp.now(),
      };

      final user = UserModel.fromJson(userJson);
      expect(user.role, 'customer');
      expect(user.createdAt, isA<DateTime>());
    });

    test('RestaurantModel and DeliveryAreaModel parse fees cleanly', () {
      final restJson = {
        'id': 'rest-1',
        'name': 'Food Fight Flagship',
        'rating': '4.9',
        'deliveryTimeMinutes': 30,
        'deliveryFee': 150,
      };

      final rest = RestaurantModel.fromJson(restJson);
      expect(rest.rating, 4.9);
      expect(rest.deliveryTimeMinutes, 30);
      expect(rest.deliveryFee, 150.0);

      final areaJson = {
        'id': 'area-1',
        'name': 'Gulberg III',
        'deliveryFee': 80,
      };

      final area = DeliveryAreaModel.fromJson(areaJson);
      expect(area.deliveryCharge, 80.0);
    });

    test('CartItemModel properly calculates item total with addons', () {
      final cartItem = CartItemModel(
        food: FoodModel(
          id: 'item-1',
          name: 'Supreme Pizza',
          description: 'Spicy pizza',
          price: 1000,
          imageEmoji: '🍕',
          category: 'Pizza',
        ),
        quantity: 2,
        selectedVariant: const MenuVariant(label: 'Large', price: 1400.0),
        selectedAddons: const [
          MenuAddon(name: 'Extra Cheese', price: 150.0),
          MenuAddon(name: 'Jalapeno', price: 50.0),
        ],
      );

      // (1400 + 150 + 50) * 2 = 1600 * 2 = 3200
      expect(cartItem.totalPrice, 3200.0);
      expect(cartItem.singleUnitPrice, 1600.0);
    });

    test('ReviewModel safely parses fromJson', () {
      final json = {
        'id': 'rev-1',
        'itemId': 'item-101',
        'branchId': 'branch_1',
        'userId': 'user-1',
        'userName': 'Ali Raza',
        'rating': 5,
        'comment': 'Best pizza ever',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      };
      final rev = ReviewModel.fromJson(json);
      expect(rev.rating, 5.0);
      expect(rev.userName, 'Ali Raza');
    });
  });
}
