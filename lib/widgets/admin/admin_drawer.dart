import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/core/constants/app_constants.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/providers/chat_provider.dart';
import 'package:food_fight/theme/theme_provider.dart';

/// Admin Navigation Drawer organized into structured functional sections
class AdminDrawer extends StatelessWidget {
  final String currentRoute;

  const AdminDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Admin Profile & Branding Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF800020), Color(0xFF4A0012)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          AppConstants.logoIconPath,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Food Fight Admin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user?.isSubAdmin == true ? 'SUB-ADMIN' : 'BRANCH ADMIN',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (user?.branchId != null) ...[
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  user!.branchId!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // DASHBOARD
                  _buildSectionHeader('DASHBOARD', colorScheme),
                  _buildItem(
                    context,
                    title: 'Dashboard Overview',
                    icon: Icons.dashboard_rounded,
                    route: '/admin/dashboard',
                  ),

                  // MENU MANAGEMENT (guarded)
                  if (user == null || user.can('menu') || user.can('categories') || user.can('coupons')) ...[
                    _buildSectionHeader('MENU MANAGEMENT', colorScheme),
                    if (user == null || user.can('menu')) ...[
                      _buildItem(
                        context,
                        title: 'Menu Items',
                        icon: Icons.restaurant_menu_rounded,
                        route: '/admin/menu',
                      ),
                      _buildItem(
                        context,
                        title: 'Add New Item',
                        icon: Icons.add_circle_outline_rounded,
                        route: '/admin/menu/add',
                      ),
                    ],
                    if (user == null || user.can('categories'))
                      _buildItem(
                        context,
                        title: 'Categories',
                        icon: Icons.category_rounded,
                        route: '/admin/categories',
                      ),
                    if (user == null || user.can('coupons'))
                      _buildItem(
                        context,
                        title: 'Deals & Coupons',
                        icon: Icons.local_offer_rounded,
                        route: '/admin/coupons',
                      ),
                  ],

                  // ORDER MANAGEMENT (guarded)
                  if (user == null || user.can('orders') || user.can('chats')) ...[
                    _buildSectionHeader('ORDER MANAGEMENT', colorScheme),
                    if (user == null || user.can('orders'))
                      _buildItem(
                        context,
                        title: 'Orders & Dispatch',
                        icon: Icons.receipt_long_rounded,
                        route: '/admin/orders',
                      ),
                    if (user == null || user.can('chats'))
                      _buildItem(
                        context,
                        title: 'Customer Chats',
                        icon: Icons.chat_rounded,
                        route: '/admin/chats',
                        badgeCount: context.watch<ChatProvider>().totalAdminUnread,
                      ),
                  ],

                  // CUSTOMER MANAGEMENT (guarded)
                  if (user == null || user.can('customers')) ...[
                    _buildSectionHeader('CUSTOMER MANAGEMENT', colorScheme),
                    _buildItem(
                      context,
                      title: 'Customers',
                      icon: Icons.people_alt_rounded,
                      route: '/admin/customers',
                    ),
                  ],

                  // DELIVERY & RIDERS (guarded)
                  if (user == null || user.can('delivery_areas') || user.can('riders')) ...[
                    _buildSectionHeader('DELIVERY & RIDERS', colorScheme),
                    if (user == null || user.can('delivery_areas'))
                      _buildItem(
                        context,
                        title: 'Delivery Areas & Fees',
                        icon: Icons.map_rounded,
                        route: '/admin/delivery-areas',
                      ),
                    if (user == null || user.can('riders'))
                      _buildItem(
                        context,
                        title: 'Fleet & Delivery Riders',
                        icon: Icons.delivery_dining_rounded,
                        route: '/admin/riders',
                      ),
                  ],

                  // REPORTS (guarded)
                  if (user == null || user.can('reports')) ...[
                    _buildSectionHeader('REPORTS & ANALYTICS', colorScheme),
                    _buildItem(
                      context,
                      title: 'Sales & Performance',
                      icon: Icons.insights_rounded,
                      route: '/admin/reports',
                    ),
                  ],

                  // SUB-ADMIN MANAGEMENT (only for full branch admin)
                  if (user != null && !user.isSubAdmin) ...[
                    _buildSectionHeader('STAFF & PERMISSIONS', colorScheme),
                    _buildItem(
                      context,
                      title: 'Sub-Admin Management',
                      icon: Icons.admin_panel_settings_rounded,
                      route: '/admin/sub-admins',
                      color: AppColors.darkBrown,
                    ),
                  ],

                  // PREFERENCES & NAVIGATION
                  _buildSectionHeader('PREFERENCES', colorScheme),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Theme',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<ThemeMode>(
                              segments: const [
                                ButtonSegment(
                                  value: ThemeMode.light,
                                  icon: Icon(Icons.wb_sunny_outlined, size: 14),
                                  label: Text('Light', style: TextStyle(fontSize: 11)),
                                ),
                                ButtonSegment(
                                  value: ThemeMode.system,
                                  icon: Icon(Icons.auto_mode_rounded, size: 14),
                                  label: Text('Auto', style: TextStyle(fontSize: 11)),
                                ),
                                ButtonSegment(
                                  value: ThemeMode.dark,
                                  icon: Icon(Icons.nightlight_round, size: 14),
                                  label: Text('Dark', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                              selected: {themeProvider.themeMode},
                              onSelectionChanged: (selected) {
                                themeProvider.setThemeMode(selected.first);
                              },
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _buildItem(
                    context,
                    title: 'Switch to Customer View',
                    icon: Icons.swap_horiz_rounded,
                    route: '/home',
                    color: AppColors.primaryYellow,
                  ),
                ],
              ),
            ),

            // Sign Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Material(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
    Color? color,
    int? badgeCount,
  }) {
    final isSelected = currentRoute == route;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
      child: Material(
        color: isSelected
            ? AppColors.brandYellow.withValues(alpha: 0.16)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
          leading: Icon(
            icon,
            color: isSelected
                ? AppColors.brandYellow
                : (color ?? colorScheme.onSurfaceVariant),
            size: 20,
          ),
          trailing: badgeCount != null && badgeCount > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: AppColors.brandMaroon,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : null,
          title: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? (Theme.of(context).brightness == Brightness.dark ? AppColors.brandYellow : AppColors.brandMaroon)
                  : (color ?? colorScheme.onSurface),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            if (!isSelected) {
              if (route == '/admin/dashboard') {
                Navigator.of(context).pushNamedAndRemoveUntil('/admin/dashboard', (r) => false);
              } else if (route == '/home') {
                Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
              } else {
                if (currentRoute == '/admin/dashboard') {
                  Navigator.of(context).pushNamed(route);
                } else {
                  Navigator.of(context).pushReplacementNamed(route);
                }
              }
            }
          },
        ),
      ),
    );
  }
}
