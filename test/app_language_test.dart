import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/localization/app_language.dart';
import 'package:food_fight/screens/settings/settings_screen.dart';
import 'package:food_fight/theme/theme_provider.dart';
import 'package:food_fight/widgets/navigation/floating_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

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
