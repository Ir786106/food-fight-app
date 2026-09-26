import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

// Customer & Core Providers
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/category_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/coupon_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/delivery_area_provider.dart';

// Restaurant Admin Providers
import 'providers/report_provider.dart';
import 'providers/admin_dashboard_provider.dart';

// Platform Super Admin Providers
import 'providers/super_admin_provider.dart';
import 'providers/admin_account_provider.dart';
import 'providers/audit_log_provider.dart';

// Supabase & Routing
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'routes/app_routes.dart';

/// ============================================================================
/// APPLICATION ENTRY POINT
/// ============================================================================
/// Initializes core backend services (Firebase & Supabase), loads persistent
/// theme preferences, and bootstraps the application widget tree with
/// multi-panel state management.
void main() async {
  // Ensure Flutter engine bindings are fully initialized before native platform calls
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase Services (Authentication, Cloud Firestore, Cloud Messaging)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  // 2. Initialize Supabase Media Storage (Exclusively handles food item pictures & banners)
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    debugPrint('Supabase Storage initialized successfully (Bucket: ${SupabaseConfig.bucketName})');
  } catch (e) {
    debugPrint('Supabase storage initialization warning: $e');
  }

  // 3. Restore persisted theme preference (Dark Mode / Light Mode / System default)
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeMode();

  // 4. Launch the root application widget with preloaded theme state
  runApp(FoodFightApp(themeProvider: themeProvider));
}

/// ============================================================================
/// ROOT APPLICATION WIDGET & STATE MANAGEMENT REGISTRY
/// ============================================================================
/// Defines the MultiProvider hierarchy for the 3 distinct application panels:
/// - Customer Panel (Menu browsing, cart calculation, live tracking, order history)
/// - Restaurant Admin Panel (KPI stats, category/menu CRUD, order pipeline advancing)
/// - Platform Super Admin Panel (System switches, admin provisioning, audit trails)
class FoodFightApp extends StatelessWidget {
  final ThemeProvider? themeProvider;

  const FoodFightApp({super.key, this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = themeProvider ?? ThemeProvider();

    return MultiProvider(
      providers: [
        // ---------------------------------------------------------------------
        // Core Identity & Session State
        // ---------------------------------------------------------------------
        // Manages user session, login, signup, role detection (customer/admin/super_admin)
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // ---------------------------------------------------------------------
        // Customer Storefront State
        // ---------------------------------------------------------------------
        // Manages cart items, variant/add-on selections, coupon discounts, and delivery charges
        ChangeNotifierProvider(create: (_) => CartProvider()),

        // Live category streaming and filtering
        ChangeNotifierProvider(create: (_) => CategoryProvider()),

        // Live menu items with variant pricing (Small, Medium, Large, XL) and add-ons
        ChangeNotifierProvider(create: (_) => MenuProvider()),

        // Order placement, customer order history, and 6-stage live status tracking
        ChangeNotifierProvider(create: (_) => OrderProvider()),

        // Promo codes and discount validation rules
        ChangeNotifierProvider(create: (_) => CouponProvider()),

        // Customer account insights, order counts, and lifetime value analytics
        ChangeNotifierProvider(create: (_) => CustomerProvider()),

        // Delivery zones, fee calculations, and active delivery coverage areas
        ChangeNotifierProvider(create: (_) => DeliveryAreaProvider()),

        // ---------------------------------------------------------------------
        // Restaurant Admin Panel State
        // ---------------------------------------------------------------------
        // Sales analytics, day-by-day revenue breakdown, and top-selling food items
        ChangeNotifierProvider(create: (_) => ReportProvider()),

        // Live KPI dashboard (daily/weekly/monthly revenue, order status pipeline counts)
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),

        // ---------------------------------------------------------------------
        // Platform Super Admin Panel State
        // ---------------------------------------------------------------------
        // Platform-wide metrics, kitchen master switch (open/closed), and maintenance mode
        ChangeNotifierProvider(create: (_) => SuperAdminProvider()),

        // Admin account provisioning, suspension, activation, and permission controls
        ChangeNotifierProvider(create: (_) => AdminAccountProvider()),

        // System-wide audit trail capturing actions across orders, menu, users, and settings
        ChangeNotifierProvider(create: (_) => AuditLogProvider()),

        // Global theme mode (Light / Dark mode toggle)
        ChangeNotifierProvider.value(value: effectiveTheme),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // Design system themes for Customer, Admin, and Super Admin panels
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // Application entry route with animated brand presentation
            initialRoute: '/splash',

            // Centralized role-guarded routing table
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
