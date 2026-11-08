import 'core/config/local_demo.dart';
import 'core/config/app_edition.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_language.dart';
import 'widgets/common/session_bindings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/category_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/coupon_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/delivery_area_provider.dart';

import 'providers/report_provider.dart';
import 'providers/admin_dashboard_provider.dart';

import 'providers/super_admin_provider.dart';
import 'providers/admin_account_provider.dart';
import 'providers/audit_log_provider.dart';
import 'providers/payment_method_provider.dart';
import 'providers/rider_provider.dart';
import 'providers/address_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/branch_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/deal_provider.dart';
import 'providers/loyalty_provider.dart';
import 'providers/review_provider.dart';
import 'providers/option_template_provider.dart';
import 'providers/app_update_provider.dart';

import 'dart:async';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/metrics/app_startup_metrics.dart';
import 'core/utils/logger.dart';
import 'routes/app_routes.dart';
import 'screens/common/not_found_screen.dart';

Future<void> main() => runFoodFight();

Future<void> runFoodFight({AppEdition edition = AppEdition.combined}) async {
  AppStartupMetrics.start();
  AppLogger.info('[PERF] main() started (+0ms)', tag: 'Startup');

  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('[PERF] WidgetsFlutterBinding initialized (+${AppStartupMetrics.startupStopwatch.elapsedMilliseconds}ms)', tag: 'Startup');

  if (LocalDemo.enabled) {
    await LocalDemo.connect();
  } else {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.info('[PERF] Firebase.initializeApp finished (+${AppStartupMetrics.startupStopwatch.elapsedMilliseconds}ms)', tag: 'Startup');
    } catch (e) {
      AppLogger.warn('Firebase initialization notice: $e', tag: 'Startup');
    }
  }

  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeMode();
  AppLogger.info('[PERF] ThemeProvider loaded (+${AppStartupMetrics.startupStopwatch.elapsedMilliseconds}ms)', tag: 'Startup');

  // Trigger non-blocking background bootstrap concurrently with first frame
  if (!LocalDemo.enabled) unawaited(AppBootstrap.startBackgroundBootstrap());

  final language = AppLanguage();
  await language.load();
  runApp(FoodFightApp(themeProvider: themeProvider, language: language, edition: edition));
}

class FoodFightApp extends StatelessWidget {
  final ThemeProvider? themeProvider;

  final AppLanguage? language;

  final AppEdition edition;

  const FoodFightApp({
    super.key, this.themeProvider, this.language,
    this.edition = AppEdition.combined,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.info('[PERF] First Flutter frame rendered (+${AppStartupMetrics.startupStopwatch.elapsedMilliseconds}ms)', tag: 'Startup');
    });
    final effectiveTheme = themeProvider ?? ThemeProvider();

    return ChangeNotifierProvider(create: (_) => AuthProvider(edition: edition),
      child: Consumer<AuthProvider>(builder: (context, auth, _) => MultiProvider(
      key: ValueKey(auth.currentUser?.id ?? 'guest'),
      providers: [

        ChangeNotifierProvider(create: (_) => CartProvider()),

        ChangeNotifierProvider(create: (_) => CategoryProvider()),

        ChangeNotifierProvider(create: (_) => MenuProvider()),

        ChangeNotifierProvider(create: (_) => OrderProvider()),

        ChangeNotifierProvider(create: (_) => CouponProvider()),

        ChangeNotifierProvider(create: (_) => CustomerProvider()),

        ChangeNotifierProvider(create: (_) => DeliveryAreaProvider()),

        ChangeNotifierProvider(create: (_) => ReportProvider()),

        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),

        ChangeNotifierProvider(create: (_) => SuperAdminProvider()),

        ChangeNotifierProvider(create: (_) => AdminAccountProvider()),

        ChangeNotifierProvider(create: (_) => AuditLogProvider()),

        ChangeNotifierProvider(create: (_) => PaymentMethodProvider()),

        ChangeNotifierProvider(create: (_) => RiderProvider()),

        ChangeNotifierProvider(create: (_) => AddressProvider()),

        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        ChangeNotifierProvider(create: (_) => RestaurantProvider()),

        ChangeNotifierProvider(create: (_) => BranchProvider()),

        ChangeNotifierProvider(create: (_) => ChatProvider()),

        ChangeNotifierProvider(create: (_) => DealProvider()),

        ChangeNotifierProvider(create: (_) => LoyaltyProvider()),

        ChangeNotifierProvider(create: (_) => ReviewProvider()),

        ChangeNotifierProvider(create: (_) => OptionTemplateProvider()),
        
        ChangeNotifierProvider(create: (_) => AppUpdateProvider()),
        
        ChangeNotifierProvider.value(value: effectiveTheme),
        if (language != null) ChangeNotifierProvider.value(value: language!),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKeyForSession(auth.currentUser?.id),
            title: edition == AppEdition.combined ? AppConstants.appName : edition.title,
            locale: context.watch<AppLanguage?>()?.locale ?? AppLanguage.english,
            supportedLocales: AppLanguage.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            debugShowCheckedModeBanner: false,

            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            initialRoute: '/splash',

            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              final clampedScaler = mediaQuery.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.4,
              );
              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: clampedScaler),
                child: SessionBindings(
                  child: Padding(
                    // Firebase Auth's web emulator notice is outside Flutter.
                    padding: const EdgeInsets.only(
                      bottom: LocalDemo.enabled ? 40 : 0,
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },

            routes: AppRoutes.routesFor(edition),
            onUnknownRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (context) => NotFoundScreen(routeName: settings.name),
            ),
          );
        },
      ),
    )));
  }
}
