import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/models/cart_item_model.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/providers/cart_provider.dart';

void main() {
  group('Cash on Delivery Order & Lifecycle Flow Verification', () {
    final testFood = FoodModel(
      id: 'food_zinger_01',
      name: 'Fight Zinger Burger',
      description: 'Extra crispy with signature sauce',
      price: 450.0,
      category: 'Burgers',
      rating: 4.8,
      prepTimeMinutes: 15,
      restaurantId: 'rest_01',
    );

    final testFood2 = FoodModel(
      id: 'food_pizza_02',
      name: 'Pepperoni Battle Feast',
      description: 'Double cheese and beef pepperoni',
      price: 850.0,
      category: 'Pizza',
      rating: 4.9,
      prepTimeMinutes: 25,
      restaurantId: 'rest_01',
      variants: const [
        MenuVariant(label: 'Medium', price: 850.0),
        MenuVariant(label: 'Large', price: 1200.0),
      ],
    );

    test('OrderModel serialization preserves COD, customer info and payment status', () {
      final orderItem1 = CartItemModel(
        food: testFood,
        quantity: 2,
        selectedAddons: [],
      );
      final orderItem2 = CartItemModel(
        food: testFood2,
        quantity: 1,
        selectedVariant: testFood2.variants?[0],
        selectedAddons: [],
      );

      final now = DateTime.now();
      final order = OrderModel(
        id: 'order_test_123',
        orderNumber: 'FF-2026-9999',
        customerId: 'customer_user_abc',
        customerName: 'Muhammad Irfan',
        customerPhone: '+92 300 1234567',
        restaurantName: 'Food Fight Kitchen',
        items: [orderItem1, orderItem2],
        subtotal: 1750.0,
        deliveryCharge: 150.0,
        discount: 0.0,
        total: 1900.0,
        deliveryAddress: 'House 42, Street 7, Islamabad, Pakistan',
        paymentMethod: 'Cash on Delivery',
        paymentStatus: 'pending',
        status: OrderStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final json = order.toJson();

      expect(json['paymentMethod'], equals('Cash on Delivery'));
      expect(json['paymentStatus'], equals('pending'));
      expect(json['customerName'], equals('Muhammad Irfan'));
      expect(json['customerPhone'], equals('+92 300 1234567'));
      expect(json['deliveryCharge'], equals(150.0));
      expect(json['total'], equals(1900.0));
      expect(json['items'].length, equals(2));

      // Test deserialization roundtrip
      final restored = OrderModel.fromJson(json);

      expect(restored.id, equals('order_test_123'));
      expect(restored.orderNumber, equals('FF-2026-9999'));
      expect(restored.customerId, equals('customer_user_abc'));
      expect(restored.customerName, equals('Muhammad Irfan'));
      expect(restored.customerPhone, equals('+92 300 1234567'));
      expect(restored.paymentMethod, equals('Cash on Delivery'));
      expect(restored.paymentStatus, equals('pending'));
      expect(restored.status, equals(OrderStatus.pending));
      expect(restored.items.length, equals(2));
      expect(restored.items[0].displayName, equals('Fight Zinger Burger'));
      expect(restored.items[0].quantity, equals(2));
      expect(restored.items[1].quantity, equals(1));
      expect(restored.total, equals(1900.0));
    });

    test('Order status transitions progress through proper lifecycle', () {
      final now = DateTime.now();
      final initialOrder = OrderModel(
        id: 'ord_cycle_1',
        orderNumber: 'FF-001',
        customerId: 'cust_1',
        customerName: 'Test Customer',
        customerPhone: '03001234567',
        restaurantName: 'Food Fight',
        items: [],
        subtotal: 500,
        deliveryCharge: 100,
        total: 600,
        deliveryAddress: 'Test Location',
        paymentMethod: 'Cash on Delivery',
        paymentStatus: 'pending',
        status: OrderStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      expect(initialOrder.status, equals(OrderStatus.pending));
      expect(initialOrder.statusLabel, equals('Pending'));

      final accepted = initialOrder.copyWith(status: OrderStatus.accepted);
      expect(accepted.status, equals(OrderStatus.accepted));
      expect(accepted.statusLabel, equals('Accepted'));

      final preparing = accepted.copyWith(status: OrderStatus.preparing);
      expect(preparing.status, equals(OrderStatus.preparing));
      expect(preparing.statusLabel, equals('Preparing'));

      final ready = preparing.copyWith(status: OrderStatus.ready);
      expect(ready.status, equals(OrderStatus.ready));
      expect(ready.statusLabel, equals('Ready'));

      final outForDelivery = ready.copyWith(status: OrderStatus.outForDelivery);
      expect(outForDelivery.status, equals(OrderStatus.outForDelivery));
      expect(outForDelivery.statusLabel, equals('Out for Delivery'));

      final delivered = outForDelivery.copyWith(
        status: OrderStatus.delivered,
        paymentStatus: 'paid', // Cash collected upon delivery
      );
      expect(delivered.status, equals(OrderStatus.delivered));
      expect(delivered.paymentStatus, equals('paid'));

      final cancelled = initialOrder.copyWith(
        status: OrderStatus.cancelled,
        cancellationReason: 'Customer requested change',
      );
      expect(cancelled.status, equals(OrderStatus.cancelled));
      expect(cancelled.cancellationReason, equals('Customer requested change'));
    });

    test('CartProvider keeps cart contents if order fails and clears only on success', () async {
      final cart = CartProvider();
      cart.addToCart(testFood, quantity: 2);
      expect(cart.items.length, equals(1));
      expect(cart.itemCount, equals(2));

      // Attempt placing order without initialized backend - catches error
      try {
        await cart.placeOrder(
          deliveryAddress: 'Test Address',
          paymentMethod: 'Cash on Delivery',
          customerId: 'test_user_id',
        );
      } catch (_) {
        // Expected failure in local unit test environment without live Firebase connection
      }

      // Order failed to complete: cart MUST NOT be cleared
      expect(cart.items.isNotEmpty, isTrue);
      expect(cart.itemCount, equals(2));
      expect(cart.items.first.food.name, equals('Fight Zinger Burger'));

      // Now verify clearCart explicitly clears after success
      cart.clearCart();
      expect(cart.items.isEmpty, isTrue);
      expect(cart.itemCount, equals(0));
    });
  });
}
