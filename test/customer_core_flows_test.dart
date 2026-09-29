import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/providers/cart_provider.dart';

void main() {
  group('Part 1 Core Customer Flows Verification', () {
    test('1. Profile - Model serialization, fields, and update mapping', () {
      final user = UserModel(
        id: 'user_cust_001',
        name: 'Iron Fighter',
        email: 'fighter@foodfight.pk',
        phone: '03001234567',
        role: 'customer',
        isActive: true,
        profileImage: 'https://example.com/avatar.jpg',
      );

      final json = user.toJson();
      expect(json['id'], equals('user_cust_001'));
      expect(json['name'], equals('Iron Fighter'));
      expect(json['email'], equals('fighter@foodfight.pk'));
      expect(json['phone'], equals('03001234567'));
      expect(json['role'], equals('customer'));
      expect(json['profileImage'], equals('https://example.com/avatar.jpg'));

      final updated = user.copyWith(
        name: 'Golden Champion',
        phone: '03119876543',
        profileImage: 'https://example.com/new_avatar.jpg',
      );
      expect(updated.name, equals('Golden Champion'));
      expect(updated.phone, equals('03119876543'));
      expect(updated.profileImage, equals('https://example.com/new_avatar.jpg'));
      expect(updated.isCustomer, isTrue);
      expect(updated.isAdmin, isFalse);
    });

    test('2. Add to Cart - CartProvider handles item addition, quantities, and badges', () {
      final cart = CartProvider();
      final item1 = FoodModel(
        id: 'food_1',
        name: 'Spicy Chicken Roll',
        description: 'Tender chicken with garlic mayo',
        price: 320,
        category: 'Rolls',
        rating: 4.7,
        prepTimeMinutes: 10,
        restaurantId: 'rest_main',
      );

      expect(cart.itemCount, equals(0));
      expect(cart.subtotal, equals(0.0));

      // Add 1 item
      cart.addToCart(item1);
      expect(cart.itemCount, equals(1));
      expect(cart.subtotal, equals(320.0));
      expect(cart.isInCart('food_1'), isTrue);
      expect(cart.getQuantity('food_1'), equals(1));

      // Add same item again -> increments quantity
      cart.addToCart(item1, quantity: 2);
      expect(cart.itemCount, equals(3));
      expect(cart.subtotal, equals(960.0));
      expect(cart.getQuantity('food_1'), equals(3));

      // Decrement
      cart.decrementQuantity('food_1');
      expect(cart.itemCount, equals(2));
      expect(cart.subtotal, equals(640.0));
    });

    test('3. Checkout & Place Order - Formats order data correctly', () {
      final cart = CartProvider();
      final burger = FoodModel(
        id: 'food_burger',
        name: 'Smash Burger',
        description: 'Double beef patty',
        price: 650,
        category: 'Burgers',
        rating: 4.9,
        prepTimeMinutes: 15,
        restaurantId: 'rest_main',
      );
      cart.addToCart(burger, quantity: 2);

      expect(cart.itemCount, equals(2));
      expect(cart.subtotal, equals(1300.0));

      final orderItem = cart.items.first;
      final now = DateTime.now();
      final order = OrderModel(
        id: 'ord_live_888',
        orderNumber: 'FF-8888',
        customerId: 'user_cust_001',
        customerName: 'Iron Fighter',
        customerPhone: '03001234567',
        restaurantName: 'Food Fight Main Kitchen',
        items: [orderItem],
        subtotal: cart.subtotal,
        deliveryCharge: cart.deliveryFee,
        discount: 0,
        total: cart.total,
        deliveryAddress: 'House 12, Street 4, Sector G-11/2, Islamabad',
        paymentMethod: 'Cash on Delivery',
        paymentStatus: 'pending',
        status: OrderStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      expect(order.orderNumber, equals('FF-8888'));
      expect(order.subtotal, equals(1300.0));
      expect(order.total, equals(1300.0 + 150.0)); // Default 150 fee
      expect(order.paymentMethod, equals('Cash on Delivery'));
      expect(order.status, equals(OrderStatus.pending));
      expect(order.deliveryAddress, contains('Islamabad'));
    });

    test('4. Orders - Query filtering and status tracking', () {
      final now = DateTime.now();
      final orders = [
        OrderModel(
          id: 'ord_1',
          orderNumber: 'FF-1001',
          customerId: 'user_A',
          restaurantName: 'Food Fight',
          items: const [],
          subtotal: 500,
          total: 650,
          deliveryAddress: 'Islamabad',
          paymentMethod: 'Cash on Delivery',
          status: OrderStatus.preparing,
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now,
        ),
        OrderModel(
          id: 'ord_2',
          orderNumber: 'FF-1002',
          customerId: 'user_A',
          restaurantName: 'Food Fight',
          items: const [],
          subtotal: 800,
          total: 950,
          deliveryAddress: 'Islamabad',
          paymentMethod: 'Cash on Delivery',
          status: OrderStatus.delivered,
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now,
        ),
        OrderModel(
          id: 'ord_3',
          orderNumber: 'FF-1003',
          customerId: 'user_B',
          restaurantName: 'Food Fight',
          items: const [],
          subtotal: 1200,
          total: 1350,
          deliveryAddress: 'Lahore',
          paymentMethod: 'Cash on Delivery',
          status: OrderStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Filter for user_A
      final userAOrders = orders.where((o) => o.customerId == 'user_A').toList();
      expect(userAOrders.length, equals(2));

      // Separate active vs past
      final active = userAOrders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).toList();
      final past = userAOrders.where((o) => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled).toList();

      expect(active.length, equals(1));
      expect(active.first.orderNumber, equals('FF-1001'));
      expect(active.first.status, equals(OrderStatus.preparing));

      expect(past.length, equals(1));
      expect(past.first.orderNumber, equals('FF-1002'));
      expect(past.first.status, equals(OrderStatus.delivered));
    });
  });
}
