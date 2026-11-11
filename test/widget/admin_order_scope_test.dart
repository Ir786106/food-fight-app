import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/localization/app_language.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/providers/customer_provider.dart';
import 'package:food_fight/providers/order_provider.dart';
import 'package:food_fight/screens/admin/orders/admin_orders_screen.dart';
import 'package:food_fight/screens/admin/customers/manage_customers_screen.dart';
import 'package:provider/provider.dart';

void main() {
  Widget app(String? branchId, _OrdersSpy orders) => MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => _BranchAdmin(branchId)),
      ChangeNotifierProvider<OrderProvider>.value(value: orders),
    ],
    child: const MaterialApp(home: AdminOrdersScreen()),
  );

  testWidgets('branch admin opens and refreshes the same order scope', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 840);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final orders = _OrdersSpy();
    addTearDown(orders.dispose);
    await tester.pumpWidget(app('branch-a', orders));
    await tester.pump();
    expect(orders.scopes, ['branch-a']);
    await tester.tap(find.byTooltip('Refresh Orders'));
    expect(orders.refreshes, 1);
    expect(orders.scopes, ['branch-a']);
  });

  testWidgets('unassigned branch admin starts no order query', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 840);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final orders = _OrdersSpy();
    addTearDown(orders.dispose);
    await tester.pumpWidget(app(null, orders));
    expect(orders.scopes, isEmpty);
    expect(find.textContaining('needs a branch assignment'), findsOneWidget);
  });

  testWidgets('customer directory translates search and status in Urdu RTL',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 760);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => _BranchAdmin('a')),
        ChangeNotifierProvider<CustomerProvider>(create: (_) => _CustomersStub()),
      ],
      child: MaterialApp(
        locale: AppLanguage.urdu,
        supportedLocales: AppLanguage.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: const ManageCustomersScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    final heading = find.text('صارفین کی فہرست');
    expect(heading, findsOneWidget);
    expect(find.text('ڈیش بورڈ'), findsOneWidget);
    expect(find.text('گفتگو'), findsOneWidget);
    expect(Directionality.of(tester.element(heading)), TextDirection.rtl);
    final contact = tester.widget<Text>(find.text('customer@example.com • 03001234567'));
    expect(contact.textDirection, TextDirection.ltr);
    expect(find.text('بلاک شدہ'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'unknown');
    await tester.pumpAndSettle();
    expect(find.text('آپ کی تلاش سے کوئی صارف نہیں ملا۔'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _CustomersStub extends CustomerProvider {
  @override
  Future<void> loadCustomers({String? branchId, bool scopeChanged = false}) async {
    notifyListenersPostFrame();
  }

  @override
  List<UserModel> get customers => searchQuery.isEmpty
      ? [
          UserModel.fromJson({
            'id': 'customer',
            'name': 'Customer',
            'email': 'customer@example.com',
            'phone': '03001234567',
            'isActive': false,
          }),
        ]
      : [];
}

class _BranchAdmin extends AuthProvider {
  _BranchAdmin(String? branchId)
      : currentUser = UserModel.fromJson({
          'id': 'manager',
          'name': 'Branch manager',
          'role': 'admin',
          'branchId': branchId,
        });

  @override
  final UserModel currentUser;

  @override
  bool get isSuperAdmin => false;
}

class _OrdersSpy extends OrderProvider {
  final scopes = <String?>[];
  int refreshes = 0;

  @override
  void watchAdminOrders({String? status, String? branchId}) {
    scopes.add(branchId);
  }

  @override
  bool isWatchingAdminScope(String? branchId) => scopes.contains(branchId);

  @override
  void refreshAdminOrders() => refreshes++;
}
