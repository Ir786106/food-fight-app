import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/services/checkout_service.dart';

void main() {
  test('missing checkout endpoint gets a cart-preserving message', () {
    final error =
        FirebaseFunctionsException(code: 'not-found', message: 'NOT_FOUND');
    expect(CheckoutService.errorMessage(error),
        'Checkout service is unavailable. Your cart is still saved.');
  });

  test('missing menu items prompt the customer to update the cart', () {
    final error = FirebaseFunctionsException(
        code: 'not-found',
        message: 'A menu item is no longer available. Refresh your cart.');
    expect(CheckoutService.errorMessage(error), contains('Update your cart'));
  });

  test('network timeouts suggest a connection check', () {
    final error =
        FirebaseFunctionsException(code: 'deadline-exceeded', message: '');
    expect(
        CheckoutService.errorMessage(error), contains('Check your connection'));
  });
}
