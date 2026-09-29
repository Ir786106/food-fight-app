import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/models/branch_model.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/models/category_model.dart';
import 'package:food_fight/models/coupon_model.dart';
import 'package:food_fight/models/delivery_area_model.dart';
import 'package:food_fight/models/admin/admin_account_model.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/providers/cart_provider.dart';

void main() {
  group('Part 2.1 — Multi-Branch Data Models & Scoping', () {
    test('BranchModel serialization, deserialization, and financial profit calculation', () {
      final now = DateTime.now();
      final branch = BranchModel(
        id: 'branch-lahore-johar-town',
        name: 'Food Fight - Johar Town',
        address: 'Main Boulevard, Phase 2, Johar Town',
        city: 'Lahore',
        phone: '+92 42 35001122',
        status: 'active',
        revenue: 1250000.0,
        orderCount: 840,
        expenses: 780000.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(branch.isActive, isTrue);
      expect(branch.profit, equals(470000.0)); // 1,250,000 - 780,000

      final json = branch.toJson();
      expect(json['id'], 'branch-lahore-johar-town');
      expect(json['revenue'], 1250000.0);
      expect(json['expenses'], 780000.0);

      final restored = BranchModel.fromJson(json);
      expect(restored.id, branch.id);
      expect(restored.name, branch.name);
      expect(restored.profit, equals(470000.0));
    });

    test('MenuItemModel and FoodModel retain branchId scoping', () {
      final now = DateTime.now();
      final menuItem = MenuItemModel(
        id: 'item-burger-01',
        name: 'Tower Burger 🥊',
        description: 'Double beef patty',
        price: 750,
        categoryId: 'burgers',
        branchId: 'branch-lahore-johar-town',
        createdAt: now,
        updatedAt: now,
      );

      expect(menuItem.branchId, equals('branch-lahore-johar-town'));
      final json = menuItem.toJson();
      expect(json['branchId'], equals('branch-lahore-johar-town'));

      final food = FoodModel.fromMenuItem(menuItem);
      expect(food.branchId, equals('branch-lahore-johar-town'));
    });

    test('OrderModel retains branchId scoping', () {
      final now = DateTime.now();
      final order = OrderModel(
        id: 'ord-1234',
        orderNumber: 'FF-5001',
        branchId: 'branch-lahore-gulberg',
        customerId: 'cust-123',
        restaurantName: 'Food Fight - Gulberg',
        items: [],
        subtotal: 1500,
        total: 1650,
        paymentMethod: 'Cash on Delivery',
        deliveryAddress: 'Gulberg III, Lahore',
        createdAt: now,
        updatedAt: now,
      );

      expect(order.branchId, equals('branch-lahore-gulberg'));
      final json = order.toJson();
      expect(json['branchId'], equals('branch-lahore-gulberg'));

      final restored = OrderModel.fromJson(json);
      expect(restored.branchId, equals('branch-lahore-gulberg'));
    });

    test('CategoryModel, CouponModel, DeliveryAreaModel retain branchId scoping', () {
      final now = DateTime.now();
      final category = CategoryModel(
        id: 'cat-pizza',
        name: 'Artisan Pizzas',
        branchId: 'branch-lahore-dha',
        createdAt: now,
        updatedAt: now,
      );
      expect(category.branchId, equals('branch-lahore-dha'));
      expect(category.toJson()['branchId'], equals('branch-lahore-dha'));

      final coupon = CouponModel(
        id: 'coup-dha20',
        code: 'DHA20',
        type: 'percentage',
        value: 20,
        branchId: 'branch-lahore-dha',
        validFrom: now,
        validUntil: now.add(const Duration(days: 7)),
      );
      expect(coupon.branchId, equals('branch-lahore-dha'));
      expect(coupon.toJson()['branchId'], equals('branch-lahore-dha'));

      final deliveryArea = DeliveryAreaModel(
        id: 'area-dha-phase5',
        name: 'DHA Phase 5',
        deliveryCharge: 120,
        branchId: 'branch-lahore-dha',
        createdAt: now,
        updatedAt: now,
      );
      expect(deliveryArea.branchId, equals('branch-lahore-dha'));
      expect(deliveryArea.toJson()['branchId'], equals('branch-lahore-dha'));
    });
  });

  group('Part 2.2 — Admin Branch Scoping & Sub-Admin Permission Management', () {
    test('AdminAccountModel with branchId and sub-admin hierarchy', () {
      final parentAdmin = AdminAccountModel(
        id: 'admin-101',
        name: 'Main Branch Manager',
        email: 'manager@foodfight.pk',
        phone: '+92 300 1111111',
        role: 'admin',
        branchId: 'branch-lahore-johar-town',
      );
      expect(parentAdmin.isSubAdmin, isFalse);
      expect(parentAdmin.branchId, equals('branch-lahore-johar-town'));

      final subAdmin = AdminAccountModel(
        id: 'sub-201',
        name: 'Kitchen Assistant Sub-Admin',
        email: 'kitchen.sub@foodfight.pk',
        phone: '+92 300 2222222',
        role: 'admin',
        branchId: 'branch-lahore-johar-town',
        parentAdminId: 'admin-101',
        permissions: ['manage_orders', 'view_reports'],
      );
      expect(subAdmin.isSubAdmin, isTrue);
      expect(subAdmin.parentAdminId, equals('admin-101'));
      expect(subAdmin.branchId, equals('branch-lahore-johar-town'));
      expect(subAdmin.permissions, contains('manage_orders'));
      expect(subAdmin.permissions, contains('view_reports'));
      expect(subAdmin.permissions, isNot(contains('manage_menu')));
    });

    test('UserModel permission enforcement logic for sub-admins', () {
      final branchAdmin = UserModel(
        id: 'user-admin',
        name: 'Branch Manager',
        email: 'manager@foodfight.pk',
        phone: '+92 300 1111111',
        role: 'admin',
        branchId: 'branch-lahore-gulberg',
      );

      // Branch admin has full permissions across all branch sections
      expect(branchAdmin.isSubAdmin, isFalse);
      expect(branchAdmin.can('manage_menu'), isTrue);
      expect(branchAdmin.can('manage_orders'), isTrue);
      expect(branchAdmin.can('manage_reports'), isTrue);

      final restrictedSubAdmin = UserModel(
        id: 'user-sub-admin',
        name: 'Restricted Staff',
        email: 'staff@foodfight.pk',
        phone: '+92 300 2222222',
        role: 'admin',
        branchId: 'branch-lahore-gulberg',
        parentAdminId: 'user-admin',
        permissions: [
          'manage_orders',
        ],
      );

      // Sub-admin permission checks
      expect(restrictedSubAdmin.isSubAdmin, isTrue);
      expect(restrictedSubAdmin.can('manage_orders'), isTrue);
      expect(restrictedSubAdmin.can('manage_menu'), isFalse);
      expect(restrictedSubAdmin.can('manage_reports'), isFalse);
      expect(restrictedSubAdmin.can('manage_coupons'), isFalse);
    });
  });

  group('Part 2.3 & 2.4 — Customer Multi-Branch Cart & Conflict Resolution', () {
    test('Cart accurately tracks branchId of added item', () {
      final cart = CartProvider();
      final foodJohar = FoodModel(
        id: 'f-01',
        name: 'Johar Club Burger',
        description: 'Juicy burger',
        price: 500,
        category: 'Burgers',
        rating: 4.8,
        prepTimeMinutes: 20,
        restaurantId: 'food_fight',
        branchId: 'branch-lahore-johar-town',
      );

      cart.addToCart(foodJohar);

      expect(cart.itemCount, equals(1));
      expect(cart.branchId, equals('branch-lahore-johar-town'));
      expect(cart.isDifferentBranch('branch-lahore-johar-town'), isFalse);
      expect(cart.isDifferentBranch('branch-lahore-gulberg'), isTrue);
    });

    test('Adding item from different branch with clearIfDifferentBranch resets cart to new branch', () {
      final cart = CartProvider();
      final foodJohar = FoodModel(
        id: 'f-01',
        name: 'Johar Club Burger',
        description: 'Juicy burger',
        price: 500,
        category: 'Burgers',
        rating: 4.8,
        prepTimeMinutes: 20,
        restaurantId: 'food_fight',
        branchId: 'branch-lahore-johar-town',
      );

      final foodGulberg = FoodModel(
        id: 'f-02',
        name: 'Gulberg Pizza Feast',
        description: 'Hot slice',
        price: 1200,
        category: 'Pizza',
        rating: 4.9,
        prepTimeMinutes: 30,
        restaurantId: 'food_fight',
        branchId: 'branch-lahore-gulberg',
      );

      cart.addToCart(foodJohar);
      expect(cart.branchId, equals('branch-lahore-johar-town'));

      // Add item from Gulberg with clearIfDifferentBranch flag
      cart.addToCart(foodGulberg, clearIfDifferentBranch: true);

      expect(cart.itemCount, equals(1));
      expect(cart.items.first.food.name, equals('Gulberg Pizza Feast'));
      expect(cart.branchId, equals('branch-lahore-gulberg'));
    });

    test('Clearing cart completely clears branchId', () {
      final cart = CartProvider();
      final food = FoodModel(
        id: 'f-01',
        name: 'Johar Club Burger',
        description: 'Juicy burger',
        price: 500,
        category: 'Burgers',
        rating: 4.8,
        prepTimeMinutes: 20,
        restaurantId: 'food_fight',
        branchId: 'branch-lahore-johar-town',
      );

      cart.addToCart(food);
      expect(cart.branchId, equals('branch-lahore-johar-town'));

      cart.clearCart();
      expect(cart.items, isEmpty);
      expect(cart.branchId, isNull);
    });
  });
}
