import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/localization/app_language.dart';
import 'package:food_fight/models/branch_model.dart';
import 'package:food_fight/models/order_model.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/providers/chat_provider.dart';
import 'package:food_fight/providers/rider_provider.dart';
import 'package:food_fight/providers/super_admin_provider.dart';
import 'package:food_fight/screens/rider/rider_delivery_page.dart';
import 'package:food_fight/screens/settings/settings_screen.dart';
import 'package:food_fight/screens/super_admin/branches/super_admin_branches_screen.dart';
import 'package:food_fight/theme/theme_provider.dart';
import 'package:food_fight/widgets/navigation/floating_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('uses Urdu device locale until English is saved', (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('ur', 'PK');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final language = AppLanguage();
    addTearDown(language.dispose);
    await language.load();
    expect(language.locale, AppLanguage.urdu);
    await language.select(AppLanguage.english);
    await language.load();
    expect(language.locale, AppLanguage.english);
  });

  testWidgets('Urdu branch management previews and cancels suspension in RTL',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 760);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final branch = BranchModel.fromJson({
      'id': 'branch',
      'name': 'Model Town',
      'phone': '03001234567',
      'status': 'active',
      'orderCount': 16,
    });
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SuperAdminProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        locale: AppLanguage.urdu,
        supportedLocales: AppLanguage.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: SuperAdminBranchesScreen(
          watchBranches: () => Stream.value([branch]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final heading = find.text('ریستوران کی برانچیں');
    expect(Directionality.of(tester.element(heading)), TextDirection.rtl);
    expect(find.text('مرکز'), findsOneWidget);
    expect(find.text('منتظمین'), findsOneWidget);
    await tester.tap(find.text('برانچ کی تفصیل دیکھیں'));
    await tester.pumpAndSettle();
    expect(find.textContaining('درج شدہ آرڈرز'), findsOneWidget);
    final phone = tester.widget<Text>(find.text('03001234567'));
    expect(phone.textDirection, TextDirection.ltr);
    await tester.tap(find.text('بند کریں'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('معطل کریں'));
    await tester.pumpAndSettle();
    expect(find.text('برانچ معطل کریں؟'), findsOneWidget);
    expect(find.textContaining('Model Town نئے آرڈرز'), findsOneWidget);
    await tester.tap(find.text('منسوخ کریں'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Urdu rider delivery preserves COD amount and offer actions',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final order = OrderModel.fromJson({
      'id': 'delivery',
      'orderNumber': 'FF-100',
      'status': 'assigned',
      'paymentStatus': 'pending',
      'paymentMethod': 'Cash on Delivery',
      'customerPhone': '03001234567',
      'total': 740.50,
    });
    String? accepted;
    Uri? opened;
    await tester.pumpWidget(ChangeNotifierProvider<RiderProvider>(
      create: (_) => _RiderDeliveryStub(order),
      child: MaterialApp(
        locale: AppLanguage.urdu,
        supportedLocales: AppLanguage.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: RiderDeliveryPage(
          orderId: order.id,
          advance: (order) async { accepted = order.id; },
          decline: (_) async {},
          fail: (_) async {},
          open: (uri) async { opened = uri; },
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final amount = find.text('وصول کرنے کی رقم');
    expect(amount, findsOneWidget);
    expect(Directionality.of(tester.element(amount)), TextDirection.rtl);
    expect(find.text('ڈیلیوری پر نقد ادائیگی'), findsOneWidget);
    expect(find.text('روپے 740.50'), findsOneWidget);
    final phone = tester.widget<Text>(find.text('03001234567'));
    expect(phone.textDirection, TextDirection.ltr);
    await tester.tap(find.byTooltip('فون کریں'));
    expect(opened, Uri(scheme: 'tel', path: '03001234567'));
    await tester.tap(find.text('قبول کریں'));
    await tester.pumpAndSettle();
    expect(accepted, order.id);
    expect(tester.takeException(), isNull);
  });

  test('language preference survives a fresh app session', () async {
    final first = AppLanguage();
    expect(first.locale, AppLanguage.english);
    await first.select(AppLanguage.urdu);
    final restored = AppLanguage();
    await restored.load();
    expect(restored.locale, AppLanguage.urdu);
    await restored.select(AppLanguage.english);
    await first.load();
    expect(first.locale, AppLanguage.english);
    restored.dispose();
    first.dispose();
  });

  testWidgets('settings switches visible labels and navigation direction',
      (tester) async {
    final language = AppLanguage();
    var selectedTab = -1;
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: language),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<AppLanguage>(builder: (context, current, _) {
        return MaterialApp(
          locale: current.locale,
          supportedLocales: AppLanguage.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: const SettingsScreen(),
            bottomNavigationBar: FloatingNavBar(
              currentIndex: 0,
              onTabSelected: (index) => selectedTab = index,
            ),
          ),
        );
      }),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.getCenter(find.text('Home')).dx,
        lessThan(tester.getCenter(find.text('Profile')).dx));

    final selector = find.byType(DropdownButton<Locale>);
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('اردو').last);
    await tester.pumpAndSettle();

    expect(find.text('ترتیبات'), findsOneWidget);
    final home = find.text('ہوم');
    final profile = find.text('پروفائل');
    expect(Directionality.of(tester.element(home)), TextDirection.rtl);
    expect(tester.getCenter(home).dx, greaterThan(tester.getCenter(profile).dx));
    await tester.tap(profile);
    expect(selectedTab, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    language.dispose();
  });
}

class _RiderDeliveryStub extends RiderProvider {
  _RiderDeliveryStub(this.order);

  final OrderModel order;

  @override
  List<OrderModel> get assignedDeliveries => [order];

  @override
  bool get isOnline => true;
}
