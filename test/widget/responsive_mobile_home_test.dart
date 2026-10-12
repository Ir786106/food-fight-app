import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/screens/home/home_screen.dart';
import 'package:food_fight/models/branch_model.dart';
import 'package:food_fight/models/category_model.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/models/cart_item_model.dart';
import 'package:food_fight/models/deal_model.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/providers/branch_provider.dart';
import 'package:food_fight/providers/category_provider.dart';
import 'package:food_fight/providers/menu_provider.dart';
import 'package:food_fight/providers/deal_provider.dart';
import 'package:food_fight/providers/loyalty_provider.dart';
import 'package:food_fight/providers/cart_provider.dart';
import 'package:food_fight/providers/notification_provider.dart';

class _TestCategoryProvider extends CategoryProvider {
  final List<CategoryModel> _cats;
  _TestCategoryProvider(this._cats);
  @override
  List<CategoryModel> get activeCategories => _cats;
  @override
  List<CategoryModel> get categories => _cats;
}

class _TestMenuProvider extends MenuProvider {
  final List<MenuItemModel> _items;
  _TestMenuProvider(this._items);
  @override
  List<MenuItemModel> get activeItems => _items;
  @override
  String? get currentBranchId => 'branch-1';
  @override
  void watchMenuItems({String? categoryId, bool activeOnly = false, String? branchId}) {}
}

class _TestBranchProvider extends BranchProvider {
  final BranchModel _branch;
  _TestBranchProvider(this._branch);
  @override
  BranchModel? get selectedBranch => _branch;
  @override
  List<BranchModel> get activeBranches => [_branch];
  @override
  Future<void> autoResolveNearestBranch({BuildContext? context, bool forcePrompt = false}) async {}
  @override
  String getDeliveryLabel() => 'Delivering from Food Fight Lahore • 15 min';
}

class _TestDealProvider extends DealProvider {
  @override
  List<DealModel> get activeDeals => [];
  @override
  void watchDeals({String? branchId, bool activeOnly = true}) {}
}

class _TestAuthProvider extends AuthProvider {
  @override
  UserModel? get currentUser => UserModel(
        id: 'u-1',
        name: 'Tariq Mehmood',
        email: 'tariq@example.com',
        phone: '03001234567',
        role: 'customer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}

class _TestLoyaltyProvider extends LoyaltyProvider {
  @override
  int get tokensBalance => 150;
  @override
  int get balance => 150;
}

class _TestCartProvider extends CartProvider {
  @override
  int get itemCount => 0;
  @override
  List<CartItemModel> get items => [];
}

class _TestNotificationProvider extends NotificationProvider {
  @override
  int get unreadCount => 2;
}

void main() {
  final mockBranch = BranchModel(
    id: 'branch-1',
    name: 'Food Fight – Gulberg III',
    address: 'MM Alam Road, Lahore',
    city: 'Lahore',
    phone: '042-35789000',
    status: 'active',
    latitude: 31.5115,
    longitude: 74.3537,
    deliveryRadiusKm: 12.0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final now = DateTime.now();
  final List<CategoryModel> mockCategories = [
    CategoryModel(id: 'cat-1', name: 'Burgers', order: 1, isActive: true, createdAt: now, updatedAt: now),
    CategoryModel(id: 'cat-2', name: 'Pizzas', order: 2, isActive: true, createdAt: now, updatedAt: now),
    CategoryModel(id: 'cat-3', name: 'Broast & Chicken', order: 3, isActive: true, createdAt: now, updatedAt: now),
    CategoryModel(id: 'cat-4', name: 'Fries & Sides', order: 4, isActive: true, createdAt: now, updatedAt: now),
    CategoryModel(id: 'cat-5', name: 'Beverages', order: 5, isActive: true, createdAt: now, updatedAt: now),
  ];

  final List<MenuItemModel> mockMenuItems = [
    MenuItemModel(
      id: 'item-1',
      name: 'Double Trouble Smash Burger with Melted Cheddar',
      description: 'Two smashed beef patties, house secret sauce, pickles and cheddar',
      price: 850,
      categoryId: 'cat-1',
      branchId: 'branch-1',
      rating: 4.9,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    MenuItemModel(
      id: 'item-2',
      name: 'Classic Pepperoni Pizza',
      description: 'Stone-baked with rich mozzarella and spicy pepperoni',
      price: 1350,
      categoryId: 'cat-2',
      branchId: 'branch-1',
      rating: 4.8,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    MenuItemModel(
      id: 'item-3',
      name: 'Crispy Broast Quarter',
      description: 'Golden fried chicken quarter served with garlic mayo',
      price: 650,
      categoryId: 'cat-3',
      branchId: 'branch-1',
      rating: 4.7,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  Widget buildTestApp({
    required double width,
    required double textScale,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CategoryProvider>.value(value: _TestCategoryProvider(mockCategories)),
        ChangeNotifierProvider<MenuProvider>.value(value: _TestMenuProvider(mockMenuItems)),
        ChangeNotifierProvider<BranchProvider>.value(value: _TestBranchProvider(mockBranch)),
        ChangeNotifierProvider<DealProvider>.value(value: _TestDealProvider()),
        ChangeNotifierProvider<AuthProvider>.value(value: _TestAuthProvider()),
        ChangeNotifierProvider<LoyaltyProvider>.value(value: _TestLoyaltyProvider()),
        ChangeNotifierProvider<CartProvider>.value(value: _TestCartProvider()),
        ChangeNotifierProvider<NotificationProvider?>.value(value: _TestNotificationProvider()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 840),
            textScaler: TextScaler.linear(textScale),
          ),
          child: const HomeScreen(),
        ),
      ),
    );
  }

  group('Mobile Customer Panel Responsive & RenderFlex Overflow Verification', () {
    const testWidths = [320.0, 360.0, 393.0, 412.0];
    const textScales = [1.0, 1.3, 1.5];

    for (final width in testWidths) {
      for (final scale in textScales) {
        testWidgets('Width ${width.toInt()}dp with ${scale}x text scale renders with ZERO overflow', (tester) async {
          tester.view.physicalSize = Size(width * 2, 840 * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(buildTestApp(width: width, textScale: scale));
          await tester.pump();

          // Verify no exceptions or RenderFlex overflow occurred
          final exception = tester.takeException();
          expect(exception, isNull);

          // Verify greeting is rendered
          expect(find.textContaining('Tariq'), findsOneWidget);

          // Verify delivery label is rendered without truncation crash
          expect(find.textContaining('Delivering from Food Fight'), findsOneWidget);

          // Verify category chips are present
          expect(find.text('Burgers'), findsWidgets);

          // Clean up widget tree
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });
}
