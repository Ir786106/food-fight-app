import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/errors/app_exception.dart';
import 'package:food_fight/core/utils/validator_utils.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/widgets/common/network_image_view.dart';

void main() {
  group('AuthProvider Error Parsing Tests', () {
    test('Translates permission-denied to clear user message', () {
      final msg = AuthProvider.parseError('permission-denied');
      expect(msg, "You don't have permission to perform this action.");
    });

    test('Translates network-request-failed to internet guidance', () {
      final msg = AuthProvider.parseError('network-request-failed');
      expect(msg, 'Network connection failed. Please check your internet connection.');
    });

    test('Translates timeout to 20-second timeout message', () {
      final msg = AuthProvider.parseError('timeout');
      expect(msg, 'Request timed out after 20 seconds. Please check your internet connection.');
    });

    test('Translates user-disabled to account disabled message', () {
      final msg = AuthProvider.parseError('user-disabled');
      expect(msg, 'This user account has been disabled. Please contact support.');
    });

    test('Translates typeerror to clean data parsing message', () {
      final msg = AuthProvider.parseError('typeerror: type int is not a subtype of double');
      expect(msg, 'Data parsing error occurred. Please contact support.');
    });

    test('Unwraps AppException cleanly', () {
      final appEx = AppException(message: 'Custom business logic error message');
      final msg = AuthProvider.parseError(appEx);
      expect(msg, 'Custom business logic error message');
    });

    test('Falls back to custom fallback if string is unknown', () {
      final msg = AuthProvider.parseError(null, 'Fallback test error');
      expect(msg, 'Fallback test error');
    });
  });

  group('ValidatorUtils Phone and Password Tests', () {
    test('Validates Pakistani phone numbers correctly', () {
      // Valid Pakistani mobile formats
      expect(ValidatorUtils.isValidPhone('03001234567'), isTrue);
      expect(ValidatorUtils.isValidPhone('+923001234567'), isTrue);
      expect(ValidatorUtils.isValidPhone('923001234567'), isTrue);
      expect(ValidatorUtils.isValidPhone('03129876543'), isTrue);
      expect(ValidatorUtils.isValidPhone('03451122334'), isTrue);

      // Invalid formats
      expect(ValidatorUtils.isValidPhone(''), isFalse);
      expect(ValidatorUtils.isValidPhone('12345'), isFalse);
      expect(ValidatorUtils.isValidPhone('0211234567'), isFalse); // Landline
      expect(ValidatorUtils.isValidPhone('+12345678901'), isFalse); // Non-Pakistani
      expect(ValidatorUtils.isValidPhone('abcdefghijk'), isFalse);

      // validatePhone method output
      expect(ValidatorUtils.validatePhone('03001234567'), isNull);
      expect(ValidatorUtils.validatePhone(null), isNotNull);
      expect(ValidatorUtils.validatePhone('0213344556'), isNotNull);
    });

    test('Validates passwords correctly', () {
      expect(ValidatorUtils.isValidPassword('123456'), isTrue);
      expect(ValidatorUtils.isValidPassword('FoodFight2026!'), isTrue);
      expect(ValidatorUtils.isValidPassword('12345'), isFalse);
      expect(ValidatorUtils.isValidPassword(''), isFalse);

      expect(ValidatorUtils.validatePassword('password123'), isNull);
      expect(ValidatorUtils.validatePassword('123'), isNotNull);
      expect(ValidatorUtils.validatePassword(null), isNotNull);
    });
  });

  group('Model Parsing & Null Safety Tests', () {
    test('MenuItemModel handles int/double/string price conversions gracefully', () {
      final map = {
        'id': 'burger_001',
        'name': 'Gourmet Crunch Burger',
        'description': 'Crispy chicken patty with secret spicy sauce',
        'price': 650, // int
        'discount': 15, // int
        'finalPrice': '552.5', // string
        'prepTimeMinutes': '20', // string
        'rating': 4.8,
        'imageUrl': 'https://storage.example.com/burger.jpg',
        'isActive': true,
      };

      final item = MenuItemModel.fromJson(map);
      expect(item.id, 'burger_001');
      expect(item.name, 'Gourmet Crunch Burger');
      expect(item.price, 650.0);
      expect(item.discount, 15.0);
      expect(item.finalPrice, 552.5);
      expect(item.prepTimeMinutes, 20);
      expect(item.rating, 4.8);
      expect(item.isActive, isTrue);
    });

    test('UserModel defaults to customer role if missing or empty', () {
      final map = {
        'id': 'user_test_999',
        'email': 'customer@foodfight.pk',
        'name': 'Food Lover',
      };

      final user = UserModel.fromJson(map);
      expect(user.id, 'user_test_999');
      expect(user.email, 'customer@foodfight.pk');
      expect(user.name, 'Food Lover');
      expect(user.role, 'customer');
      expect(user.isCustomer, isTrue);
      expect(user.isAdmin, isFalse);
    });
  });

  group('NetworkImageView Fallback Widget Tests', () {
    testWidgets('Renders neutral branded fallback icon when imageUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NetworkImageView(
              imageUrl: null,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // Verify neutral branded fallback icon appears
      expect(find.byIcon(Icons.fastfood_rounded), findsOneWidget);
    });

    testWidgets('Renders fallback icon when fallbackEmoji is empty and imageUrl is empty string', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NetworkImageView(
              imageUrl: '',
              fallbackEmoji: '',
              fallbackIcon: Icons.fastfood_rounded,
              width: 80,
              height: 80,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fastfood_rounded), findsOneWidget);
    });
  });
}
