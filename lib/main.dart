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

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    debugPrint('Supabase Storage initialized successfully (Bucket: ${SupabaseConfig.bucketName})');
  } catch (e) {
    debugPrint('Supabase storage initialization warning: $e');
  }

  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeMode();

  runApp(FoodFightApp(themeProvider: themeProvider));
}

class FoodFightApp extends StatelessWidget {
  final ThemeProvider? themeProvider;

  const FoodFightApp({super.key, this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = themeProvider ?? ThemeProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

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

        ChangeNotifierProvider.value(value: effectiveTheme),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            initialRoute: '/splash',

            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
