import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/core/theme/super_admin_theme.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/theme/app_theme.dart';

// Customer Screens
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/home/main_navigation_screen.dart';
import '../screens/restaurant/restaurant_detail_screen.dart';
import '../screens/food/food_detail_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/order_success_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/orders/order_tracking_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/address/address_screen.dart';
import '../screens/address/add_address_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/settings_screen.dart';

// Admin Screens
import '../screens/admin/dashboard/admin_dashboard_screen.dart';
import '../screens/admin/orders/admin_orders_screen.dart';
import '../screens/admin/menu/manage_menu_screen.dart';
import '../screens/admin/menu/add_edit_menu_item_screen.dart';
import '../screens/admin/categories/manage_categories_screen.dart';
import '../screens/admin/customers/manage_customers_screen.dart';
import '../screens/admin/delivery_areas/manage_delivery_areas_screen.dart';
import '../screens/admin/coupons/manage_coupons_screen.dart';
import '../screens/admin/reports/sales_reports_screen.dart';

// Super Admin Screens
import '../screens/super_admin/dashboard/super_admin_dashboard_screen.dart';
import '../screens/super_admin/admins/super_admin_manage_admins_screen.dart';
import '../screens/super_admin/settings/super_admin_system_settings_screen.dart';
import '../screens/super_admin/audit/super_admin_audit_logs_screen.dart';

/// ============================================================================
/// APPLICATION ROUTING TABLE & ROLE-BASED ACCESS CONTROL
/// ============================================================================
/// Maps string route identifiers to screen widgets and wraps privileged routes
/// with specialized Route Guard widgets (`AdminRouteGuard`, `SuperAdminRouteGuard`).
/// This ensures unauthorized roles cannot reach restricted screens even if navigated
/// to directly.
class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    // -------------------------------------------------------------------------
    // 1. Shared & Customer Storefront Routes
    // -------------------------------------------------------------------------
    // Entry & Onboarding
    '/splash': (context) => const SplashScreen(),
    '/onboarding': (context) => const OnboardingScreen(),

    // Authentication Flows
    '/login': (context) => const LoginScreen(),
    '/signup': (context) => const SignupScreen(),
    '/forgot-password': (context) => const ForgotPasswordScreen(),
    '/reset-password': (context) => const ResetPasswordScreen(),

    // Customer Navigation & Food Discovery
    '/home': (context) => const MainNavigationScreen(),
    '/restaurant-detail': (context) => const RestaurantDetailScreen(),
    '/food-detail': (context) => const FoodDetailScreen(),
    '/menu': (context) => const MenuScreen(),
    '/search': (context) => const SearchScreen(),
    '/favorites': (context) => const FavoritesScreen(),

    // Cart, Checkout & Orders
    '/cart': (context) => const CartScreen(),
    '/checkout': (context) => const CheckoutScreen(),
    '/order-success': (context) => const OrderSuccessScreen(),
    '/order-history': (context) => const OrderHistoryScreen(),
    '/order-tracking': (context) => const OrderTrackingScreen(),

    // User Profile, Addresses & Settings
    '/profile': (context) => const ProfileScreen(),
    '/edit-profile': (context) => const EditProfileScreen(),
    '/addresses': (context) => const AddressScreen(),
    '/add-address': (context) => const AddAddressScreen(),
    '/notifications': (context) => const NotificationsScreen(),
    '/settings': (context) => const SettingsScreen(),

    // -------------------------------------------------------------------------
    // 2. Restaurant Admin Panel Routes (Protected by AdminRouteGuard)
    // -------------------------------------------------------------------------
    // Requires authenticated user with 'admin' or 'super_admin' role
    '/admin/dashboard': (context) => const AdminRouteGuard(child: AdminDashboardScreen()),
    '/admin/orders': (context) => const AdminRouteGuard(child: AdminOrdersScreen()),
    '/admin/menu': (context) => const AdminRouteGuard(child: ManageMenuScreen()),
    '/admin/menu/add': (context) => const AdminRouteGuard(child: AddEditMenuItemScreen()),
    '/admin/categories': (context) => const AdminRouteGuard(child: ManageCategoriesScreen()),
    '/admin/customers': (context) => const AdminRouteGuard(child: ManageCustomersScreen()),
    '/admin/delivery-areas': (context) => const AdminRouteGuard(child: ManageDeliveryAreasScreen()),
    '/admin/coupons': (context) => const AdminRouteGuard(child: ManageCouponsScreen()),
    '/admin/reports': (context) => const AdminRouteGuard(child: SalesReportsScreen()),

    // -------------------------------------------------------------------------
    // 3. Platform Super Admin Panel Routes (Protected by SuperAdminRouteGuard)
    // -------------------------------------------------------------------------
    // Requires authenticated user with 'super_admin' clearance exclusively
    '/super-admin/dashboard': (context) => const SuperAdminRouteGuard(child: SuperAdminDashboardScreen()),
    '/super-admin/admins': (context) => const SuperAdminRouteGuard(child: SuperAdminManageAdminsScreen()),
    '/super-admin/settings': (context) => const SuperAdminRouteGuard(child: SuperAdminSystemSettingsScreen()),
    '/super-admin/audit': (context) => const SuperAdminRouteGuard(child: SuperAdminAuditLogsScreen()),
  };
}

/// ============================================================================
/// ROUTE GUARD: RESTAURANT ADMIN
/// ============================================================================
/// Intercepts navigation to '/admin/*' endpoints:
/// - If not authenticated: Prompts user to log in via '/login'.
/// - If authenticated as customer: Blocks access and displays an Access Restricted card.
/// - If authenticated as admin or super_admin: Grants pass-through access to the child view.
class AdminRouteGuard extends StatelessWidget {
  final Widget child;

  const AdminRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Case 1: Unauthenticated
    if (!auth.isLoggedIn) {
      return _buildAccessDeniedScreen(
        context: context,
        title: 'Sign In Required',
        message: 'You must be signed in with an authorized administrator account to access this console.',
        actionLabel: 'Go to Sign In',
        onAction: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false),
        icon: Icons.lock_outline_rounded,
        accentColor: AppColors.primary,
      );
    }

    // Case 2: Authenticated but neither Admin nor Super Admin
    if (!auth.isAdmin && !auth.isSuperAdmin) {
      return _buildAccessDeniedScreen(
        context: context,
        title: 'Access Restricted',
        message: 'Your current account does not have administrative privileges for the restaurant portal.',
        actionLabel: 'Return to Customer App',
        onAction: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
        icon: Icons.shield_outlined,
        accentColor: Colors.red.shade600,
      );
    }

    // Case 3: Authorized
    return child;
  }

  Widget _buildAccessDeniedScreen({
    required BuildContext context,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    required IconData icon,
    required Color accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141419) : const Color(0xFFF9F9FB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 36, color: accentColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.getTextDark(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AdminTheme.getTextMuted(context),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Route guard protecting Super Admin-level views from unauthorized access.
/// Requires the user to be authenticated and hold 'super_admin' role.
class SuperAdminRouteGuard extends StatelessWidget {
  final Widget child;

  const SuperAdminRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Case 1: Unauthenticated
    if (!auth.isLoggedIn) {
      return _buildAccessDeniedScreen(
        context: context,
        title: 'Super Admin Authentication Required',
        message: 'This area contains platform-level governance tools. Please sign in with your Super Administrator credentials.',
        actionLabel: 'Go to Sign In',
        onAction: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false),
        icon: Icons.security_rounded,
        accentColor: SuperAdminTheme.primary,
      );
    }

    // Case 2: Authenticated but not Super Admin
    if (!auth.isSuperAdmin) {
      return _buildAccessDeniedScreen(
        context: context,
        title: 'Super Admin Clearance Required',
        message: 'Your account has restaurant-level permissions, but lacks platform governance clearance to access the Super Admin control suite.',
        actionLabel: auth.isAdmin ? 'Return to Admin Dashboard' : 'Return to Customer App',
        onAction: () {
          if (auth.isAdmin) {
            Navigator.of(context).pushNamedAndRemoveUntil('/admin/dashboard', (r) => false);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
          }
        },
        icon: Icons.gavel_rounded,
        accentColor: SuperAdminTheme.primary,
      );
    }

    // Case 3: Authorized Super Admin
    return child;
  }

  Widget _buildAccessDeniedScreen({
    required BuildContext context,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    required IconData icon,
    required Color accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: SuperAdminTheme.getBackground(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: SuperAdminTheme.getCardBg(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [SuperAdminTheme.primary, Color(0xFF230833)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SuperAdminTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 38, color: SuperAdminTheme.accentGold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: SuperAdminTheme.getTextDark(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: SuperAdminTheme.getTextMuted(context),
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SuperAdminTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
