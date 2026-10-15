import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/models/restaurant_model.dart';
import 'package:food_fight/models/branch_model.dart';
import 'package:food_fight/models/payment_method_model.dart';
import 'package:food_fight/models/address_model.dart';
import 'package:food_fight/models/delivery_area_model.dart';

import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/providers/cart_provider.dart';
import 'package:food_fight/providers/order_provider.dart';
import 'package:food_fight/providers/chat_provider.dart';
import 'package:food_fight/providers/loyalty_provider.dart';
import 'package:food_fight/providers/delivery_area_provider.dart';
import 'package:food_fight/providers/payment_method_provider.dart';
import 'package:food_fight/providers/address_provider.dart';
import 'package:food_fight/providers/restaurant_provider.dart';
import 'package:food_fight/providers/branch_provider.dart';
import 'package:food_fight/providers/coupon_provider.dart';
import 'package:food_fight/providers/rider_provider.dart';
import 'package:food_fight/providers/review_provider.dart';
import 'package:food_fight/theme/theme_provider.dart';

import 'package:food_fight/screens/food/food_detail_screen.dart';
import 'package:food_fight/screens/cart/cart_screen.dart';
import 'package:food_fight/screens/checkout/checkout_screen.dart';
import 'package:food_fight/screens/orders/order_history_screen.dart';
import 'package:food_fight/screens/rider/rider_dashboard_screen.dart';

// Lightweight in-memory test stubs that decouple widget tests from live Firebase
class StubChatProvider extends ChangeNotifier implements ChatProvider {
  @override
  int get totalUnreadForCustomer => 0;
  @override
  int get totalAdminUnread => 0;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubRestaurantProvider extends ChangeNotifier implements RestaurantProvider {
  @override
  List<RestaurantModel> get restaurants => [];
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubBranchProvider extends ChangeNotifier implements BranchProvider {
  @override
  List<BranchModel> get branches => [];
  @override
  List<BranchModel> get activeBranches => [];
  @override
  BranchModel? get selectedBranch => null;
  @override
  bool get isLoading => false;
  @override
  bool get isResolvingLocation => false;
  @override
  bool get isOutOfDeliveryArea => false;
  @override
  double? get userLatitude => null;
  @override
  double? get userLongitude => null;
  @override
  double? get distanceToNearestKm => null;
  @override
  String? get savedCity => null;
  @override
  String? get closedBranchFallbackNotice => null;
  @override
  BranchModel? get nearestBranchOutOfRange => null;
  @override
  String getDeliveryLabel() => 'Express Kitchen • Fast Delivery';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubReviewProvider extends ChangeNotifier implements ReviewProvider {
  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  double get averageRating => 4.8;
  @override
  Map<int, int> get ratingDistribution => {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  @override
  void watchItemReviews(String itemId) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubPaymentMethodProvider extends ChangeNotifier implements PaymentMethodProvider {
  @override
  List<PaymentMethodModel> get methods => [];
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubAddressProvider extends ChangeNotifier implements AddressProvider {
  @override
  List<AddressModel> get addresses => [];
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubDeliveryAreaProvider extends ChangeNotifier implements DeliveryAreaProvider {
  @override
  List<DeliveryAreaModel> get areas => [];
  @override
  List<DeliveryAreaModel> get activeAreas => [];
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubCouponProvider extends ChangeNotifier implements CouponProvider {
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubRiderProvider extends ChangeNotifier implements RiderProvider {
  @override
  List<OrderModel> get assignedDeliveries => [];
  @override
  List<OrderModel> get completedDeliveries => [];
  @override
  bool get isLoading => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Matrix specification from STEP 5:
  // 320x568 (small old phone), 360x640, 390x844, 412x915, 600x960 (small tablet),
  // 768x1024 and 1024x768 (tablet both orientations), 1280x720, 1440x900, 1920x1080 (web)
  // Text scales: 1.0x, 1.3x, 2.0x
  final deviceMatrix = <(String, Size)>[
    ('iPhone SE / Small Phone (320x568)', const Size(320, 568)),
    ('Standard Android (360x640)', const Size(360, 640)),
    ('iPhone 14 / Pro (390x844)', const Size(390, 844)),
    ('Pixel 7 / Android Large (412x915)', const Size(412, 915)),
    ('Small Tablet Portrait (600x960)', const Size(600, 960)),
    ('iPad Portrait (768x1024)', const Size(768, 1024)),
    ('iPad Landscape (1024x768)', const Size(1024, 768)),
    ('HD Laptop (1280x720)', const Size(1280, 720)),
    ('MacBook / Desktop (1440x900)', const Size(1440, 900)),
    ('FHD Desktop / Web (1920x1080)', const Size(1920, 1080)),
  ];

  final textScales = [1.0, 1.3, 2.0];

  final testFood = FoodModel(
    id: 'food_1',
    name: 'Special Double Patty Burger With Cheese',
    description: 'Juicy double beef patty layered with melted cheddar cheese and homemade secret sauce on a toasted brioche bun.',
    price: 850,
    category: 'Burgers',
    rating: 4.8,
    prepTimeMinutes: 15,
    restaurantId: 'rest_1',
    variants: [
      const MenuVariant(label: 'Regular', price: 850, description: 'Single meal portion'),
      const MenuVariant(label: 'Large Combo', price: 1250, description: 'With fries and drink'),
    ],
  );

  Widget createTestApp({
    required Widget child,
    required Size size,
    required double textScale,
    RouteSettings? settings,
  }) {
    final cart = CartProvider();
    cart.addToCart(testFood);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
        ChangeNotifierProvider<CartProvider>.value(value: cart),
        ChangeNotifierProvider<ReviewProvider>.value(value: StubReviewProvider()),
        ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
        ChangeNotifierProvider<OrderProvider>.value(value: OrderProvider()),
        ChangeNotifierProvider<ChatProvider>.value(value: StubChatProvider()),
        ChangeNotifierProvider<LoyaltyProvider>.value(value: LoyaltyProvider()),
        ChangeNotifierProvider<DeliveryAreaProvider>.value(value: StubDeliveryAreaProvider()),
        ChangeNotifierProvider<PaymentMethodProvider>.value(value: StubPaymentMethodProvider()),
        ChangeNotifierProvider<AddressProvider>.value(value: StubAddressProvider()),
        ChangeNotifierProvider<RestaurantProvider>.value(value: StubRestaurantProvider()),
        ChangeNotifierProvider<BranchProvider>.value(value: StubBranchProvider()),
        ChangeNotifierProvider<CouponProvider>.value(value: StubCouponProvider()),
        ChangeNotifierProvider<RiderProvider>.value(value: StubRiderProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF800020)),
        builder: (context, materialChild) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: materialChild ?? const SizedBox.shrink(),
          );
        },
        onGenerateRoute: (s) {
          return MaterialPageRoute(
            settings: settings ?? s,
            builder: (_) => child,
          );
        },
      ),
    );
  }

  group('Full Device Matrix Verification (10 Sizes x 3 Text Scales = Zero Overflows)', () {
    for (final (label, size) in deviceMatrix) {
      for (final scale in textScales) {
        testWidgets('FoodDetailScreen renders with zero overflow on $label @ ${scale}x scale', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            createTestApp(
              child: const FoodDetailScreen(),
              size: size,
              textScale: scale,
              settings: RouteSettings(arguments: testFood),
            ),
          );

          expect(tester.takeException(), isNull,
              reason: 'Overflow or crash on FoodDetailScreen at $label @ ${scale}x');
        });

        testWidgets('CartScreen renders with zero overflow on $label @ ${scale}x scale', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            createTestApp(
              child: const CartScreen(),
              size: size,
              textScale: scale,
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull,
              reason: 'Overflow or crash on CartScreen at $label @ ${scale}x');
        });

        testWidgets('CheckoutScreen renders with zero overflow on $label @ ${scale}x scale', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            createTestApp(
              child: const CheckoutScreen(),
              size: size,
              textScale: scale,
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull,
              reason: 'Overflow or crash on CheckoutScreen at $label @ ${scale}x');
        });

        testWidgets('OrderHistoryScreen renders with zero overflow on $label @ ${scale}x scale', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            createTestApp(
              child: const OrderHistoryScreen(),
              size: size,
              textScale: scale,
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull,
              reason: 'Overflow or crash on OrderHistoryScreen at $label @ ${scale}x');
        });

        testWidgets('RiderDashboardScreen renders with zero overflow on $label @ ${scale}x scale', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            createTestApp(
              child: const RiderDashboardScreen(),
              size: size,
              textScale: scale,
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull,
              reason: 'Overflow or crash on RiderDashboardScreen at $label @ ${scale}x');
        });
      }
    }
  });
}
