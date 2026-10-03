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
import '../screens/profile/payment_methods_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/chat/customer_chat_screen.dart';
import '../screens/loyalty/loyalty_tokens_screen.dart';

// Fleet & Rider Screens
import '../screens/admin/riders/manage_riders_screen.dart';
import '../screens/rider/rider_dashboard_screen.dart';

// Admin Screens
import '../screens/admin/dashboard/admin_dashboard_screen.dart';
import '../screens/admin/orders/admin_orders_screen.dart';
import '../screens/admin/chats/admin_chats_screen.dart';
import '../screens/admin/menu/manage_menu_screen.dart';
import '../screens/admin/menu/add_edit_menu_item_screen.dart';
import '../screens/admin/categories/manage_categories_screen.dart';
import '../screens/admin/customers/manage_customers_screen.dart';
import '../screens/admin/delivery_areas/manage_delivery_areas_screen.dart';
import '../screens/admin/coupons/manage_coupons_screen.dart';
import '../screens/admin/reports/sales_reports_screen.dart';
import '../screens/admin/sub_admins/manage_sub_admins_screen.dart';
import '../screens/admin/deals/manage_deals_screen.dart';
import '../screens/admin/reviews/admin_reviews_screen.dart';

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

    // User Profile, Addresses, Payments & Settings
    '/profile': (context) => const ProfileScreen(),
    '/edit-profile': (context) => const EditProfileScreen(),
    '/addresses': (context) => const AddressScreen(),
    '/add-address': (context) => const AddAddressScreen(),
    '/payment-methods': (context) => const PaymentMethodsScreen(),
    '/notifications': (context) => const NotificationsScreen(),
    '/settings': (context) => const SettingsScreen(),
    '/chat': (context) => const CustomerChatScreen(),
    '/loyalty': (context) => const LoyaltyTokensScreen(),

    // -------------------------------------------------------------------------
    // 2. Restaurant Admin Panel Routes (Protected by AdminRouteGuard)
    // -------------------------------------------------------------------------
    // Requires authenticated user with 'admin' or 'super_admin' role
    '/admin/dashboard': (context) => const AdminRouteGuard(child: AdminDashboardScreen()),
    '/admin/orders': (context) => const AdminRouteGuard(requiredPermission: 'orders', child: AdminOrdersScreen()),
    '/admin/chats': (context) => const AdminRouteGuard(requiredPermission: 'chats', child: AdminChatsScreen()),
    '/admin/menu': (context) => const AdminRouteGuard(requiredPermission: 'menu', child: ManageMenuScreen()),
    '/admin/menu/add': (context) => const AdminRouteGuard(requiredPermission: 'menu', child: AddEditMenuItemScreen()),
    '/admin/categories': (context) => const AdminRouteGuard(requiredPermission: 'categories', child: ManageCategoriesScreen()),
    '/admin/customers': (context) => const AdminRouteGuard(requiredPermission: 'customers', child: ManageCustomersScreen()),
    '/admin/delivery-areas': (context) => const AdminRouteGuard(requiredPermission: 'delivery_areas', child: ManageDeliveryAreasScreen()),
    '/admin/riders': (context) => const AdminRouteGuard(requiredPermission: 'riders', child: ManageRidersScreen()),
    '/admin/coupons': (context) => const AdminRouteGuard(requiredPermission: 'coupons', child: ManageCouponsScreen()),
    '/admin/deals': (context) => const AdminRouteGuard(child: ManageDealsScreen()),
    '/admin/reviews': (context) => const AdminRouteGuard(child: AdminReviewsScreen()),
    '/admin/reports': (context) => const AdminRouteGuard(requiredPermission: 'reports', child: SalesReportsScreen()),
    '/admin/sub-admins': (context) => const AdminRouteGuard(blockSubAdmin: true, child: ManageSubAdminsScreen()),

    // -------------------------------------------------------------------------
    // 3. Platform Super Admin Panel Routes (Protected by SuperAdminRouteGuard)
    // -------------------------------------------------------------------------
    // Requires authenticated user with 'super_admin' clearance exclusively
    '/super-admin/dashboard': (context) => const SuperAdminRouteGuard(child: SuperAdminDashboardScreen()),
    '/super-admin/admins': (context) => const SuperAdminRouteGuard(child: SuperAdminManageAdminsScreen()),
    '/super-admin/settings': (context) => const SuperAdminRouteGuard(child: SuperAdminSystemSettingsScreen()),
    '/super-admin/audit': (context) => const SuperAdminRouteGuard(child: SuperAdminAuditLogsScreen()),

    // -------------------------------------------------------------------------
    // 4. Delivery Rider Console Routes (Protected by RiderRouteGuard)
    // -------------------------------------------------------------------------
    '/rider/dashboard': (context) => const RiderRouteGuard(child: RiderDashboardScreen()),
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
  final String? requiredPermission;
  final bool blockSubAdmin;

  const AdminRouteGuard({
    super.key,
    required this.child,
    this.requiredPermission,
    this.blockSubAdmin = false,
  });

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
        onAction: () => Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (r) => false),
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
        onAction: () => Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/home', (r) => false),
        icon: Icons.shield_outlined,
        accentColor: AppColors.error,
      );
    }

    // Case 3: Block sub-admin from management actions (e.g. creating further sub-admins)
    final user = auth.currentUser;
    if (blockSubAdmin && (user?.isSubAdmin == true)) {
      return _buildAccessDeniedScreen(
        context: context,
        title: 'Action Prohibited',
        message: 'Sub-admin staff accounts are not authorized to manage other administrative accounts.',
        actionLabel: 'Back to Dashboard',
        onAction: () => Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/admin/dashboard', (r) => false),
        icon: Icons.admin_panel_settings_outlined,
        accentColor: AppColors.warning,
      );
    }

    // Case 4: Sub-admin permission restriction
    if (requiredPermission != null && user != null && user.isSubAdmin && !user.can(requiredPermission!)) {
      return _buildAccessDeniedScreen(
        context: context,
        title: 'Section Restricted',
        message: 'Your sub-admin account is restricted from accessing the "$requiredPermission" module. Contact your branch manager to request access.',
        actionLabel: 'Back to Dashboard',
        onAction: () => Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/admin/dashboard', (r) => false),
        icon: Icons.lock_clock_rounded,
        accentColor: AppColors.warning,
      );
    }

    // Case 5: Authorized
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
        onAction: () => Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (r) => false),
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
            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/admin/dashboard', (r) => false);
          } else {
            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/home', (r) => false);
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

/// Route guard protecting Delivery Rider Console from unauthorized access.
/// Requires user to be authenticated and hold 'delivery_rider', 'admin', or 'super_admin' role.
class RiderRouteGuard extends StatelessWidget {
  final Widget child;

  const RiderRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Case 1: Unauthenticated
    if (!auth.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delivery_dining_rounded, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'Rider Login Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Please sign in to access your delivery dispatch console.'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (r) => false),
                  child: const Text('Go to Sign In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Case 2: Authenticated but not a Rider, Admin, or Super Admin
    if (!auth.isRider && !auth.isAdmin && !auth.isSuperAdmin) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, size: 64, color: AppColors.warning),
                const SizedBox(height: 16),
                const Text(
                  'Rider Clearance Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Your account is not registered as an active delivery rider.'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/home', (r) => false),
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Case 3: Authorized
    return child;
  }
}
