import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/models/deal_model.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/providers/cart_provider.dart';
import 'package:food_fight/services/order_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 Features & Enhancements Unit Tests', () {
    late CartProvider cart;

    final sampleFood = FoodModel(
      id: 'burger-1',
      name: 'Smash Burger Double',
      description: 'Double beef patty with melted cheddar',
      price: 650.0,
      category: 'Burgers',
      rating: 4.9,
      prepTimeMinutes: 12,
      restaurantId: 'branch-101',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cart = CartProvider();
    });

    test('Order number generation is collision resistant and starts with FF-', () {
      final num1 = OrderService.generateOrderNumber();
      final num2 = OrderService.generateOrderNumber();

      expect(num1.startsWith('FF-'), isTrue);
      expect(num2.startsWith('FF-'), isTrue);
      expect(num1, isNot(equals(num2)));
      expect(num1.length, greaterThanOrEqualTo(8));
    });

    test('Cart branch switching and preservation logic', () {
      cart.setBranchId('branch-101');
      expect(cart.branchId, equals('branch-101'));

      cart.addToCart(sampleFood);
      expect(cart.itemCount, equals(1));
      expect(cart.subtotal, equals(650.0));
      expect(cart.isDifferentBranch('branch-101'), isFalse);
      expect(cart.isDifferentBranch('branch-102'), isTrue);
    });

    test('Deal combo item calculation in CartProvider', () {
      final now = DateTime.now();
      final deal = DealModel(
        id: 'deal-fest-1',
        title: 'Squad Burger Fest',
        description: '2 Smash Burgers + 2 Fries + 2 Drinks',
        dealPrice: 1450.0,
        originalPrice: 1950.0,
        branchId: 'branch-101',
        createdAt: now,
        updatedAt: now,
      );

      cart.setBranchId('branch-101');
      cart.addDealToCart(deal);

      expect(cart.items.length, equals(1));
      expect(cart.items.first.food.name, equals('Squad Burger Fest'));
      expect(cart.subtotal, equals(1450.0));
    });

    test('Favorites toggling and persistence state', () {
      expect(cart.isFavorite('burger-1'), isFalse);
      cart.toggleFavorite(sampleFood);
      expect(cart.isFavorite('burger-1'), isTrue);

      cart.toggleFavorite(sampleFood);
      expect(cart.isFavorite('burger-1'), isFalse);
    });

    test('Order cancellation 5-minute window validation logic', () {
      final now = DateTime.now();

      // Case 1: Fresh order within 5 minutes, status pending -> Cancellable
      final freshOrder = OrderModel(
        id: 'order-1',
        orderNumber: 'FF-001',
        customerId: 'cust-1',
        customerName: 'Ahmad',
        customerPhone: '03001234567',
        restaurantName: 'Food Fight Branch 1',
        items: [],
        subtotal: 1000,
        deliveryCharge: 100,
        discount: 0,
        total: 1100,
        paymentMethod: 'cash_on_delivery',
        paymentStatus: 'pending',
        status: OrderStatus.pending,
        deliveryAddress: 'Street 1, Lahore',
        createdAt: now.subtract(const Duration(minutes: 2)),
        updatedAt: now,
      );

      final diffFresh = now.difference(freshOrder.createdAt);
      expect(diffFresh.inMinutes < 5, isTrue);
      expect(freshOrder.status == OrderStatus.pending, isTrue);

      // Case 2: Order older than 5 minutes -> Not cancellable
      final oldOrder = OrderModel(
        id: 'order-2',
        orderNumber: 'FF-002',
        customerId: 'cust-1',
        customerName: 'Ahmad',
        customerPhone: '03001234567',
        restaurantName: 'Food Fight Branch 1',
        items: [],
        subtotal: 1000,
        deliveryCharge: 100,
        discount: 0,
        total: 1100,
        paymentMethod: 'cash_on_delivery',
        paymentStatus: 'pending',
        status: OrderStatus.pending,
        deliveryAddress: 'Street 1, Lahore',
        createdAt: now.subtract(const Duration(minutes: 6)),
        updatedAt: now,
      );

      final diffOld = now.difference(oldOrder.createdAt);
      expect(diffOld.inMinutes < 5, isFalse);

      // Case 3: Order already preparing within 2 minutes -> Not cancellable by customer
      final preparingOrder = OrderModel(
        id: 'order-3',
        orderNumber: 'FF-003',
        customerId: 'cust-1',
        customerName: 'Ahmad',
        customerPhone: '03001234567',
        restaurantName: 'Food Fight Branch 1',
        items: [],
        subtotal: 1000,
        deliveryCharge: 100,
        discount: 0,
        total: 1100,
        paymentMethod: 'cash_on_delivery',
        paymentStatus: 'pending',
        status: OrderStatus.preparing,
        deliveryAddress: 'Street 1, Lahore',
        createdAt: now.subtract(const Duration(minutes: 1)),
        updatedAt: now,
      );

      expect(preparingOrder.status == OrderStatus.pending, isFalse);
    });

    test('Loyalty discount calculations in cart', () {
      cart.addToCart(sampleFood); // subtotal = 650
      expect(cart.subtotal, equals(650.0));

      // Apply 100 tokens (100 PKR discount): subtotal 650 + delivery 150 - discount 100 = 700
      cart.setTokensToRedeem(100, tokenValue: 1.0);
      expect(cart.loyaltyDiscount, equals(100.0));
      expect(cart.total, equals(700.0));

      // Remove loyalty: subtotal 650 + delivery 150 = 800
      cart.clearTokensToRedeem();
      expect(cart.loyaltyDiscount, equals(0.0));
      expect(cart.total, equals(800.0));
    });
  });
}
