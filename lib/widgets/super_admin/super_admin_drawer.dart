import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/core/constants/app_constants.dart';
import 'package:food_fight/core/theme/super_admin_theme.dart';
import 'package:food_fight/providers/auth_provider.dart';

/// Navigation Drawer for Super Admin Panel
class SuperAdminDrawer extends StatelessWidget {
  final String currentRoute;

  const SuperAdminDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: SuperAdminTheme.getBackground(context),
      child: SafeArea(
        child: Column(
          children: [
            // Super Admin Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [SuperAdminTheme.primary, SuperAdminTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            AppConstants.logoIconPath,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FOOD FIGHT',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: SuperAdminTheme.accentGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: SuperAdminTheme.accentGold.withValues(alpha: 0.6)),
                              ),
                              child: const Text(
                                'SUPER ADMIN 👑',
                                style: TextStyle(
                                  color: SuperAdminTheme.accentGold,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Super Administrator',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.email ?? 'superadmin@foodfight.pk',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildNavHeader(context, 'PLATFORM CONTROL'),
                  _buildNavItem(
                    context: context,
                    icon: Icons.dashboard_rounded,
                    title: 'System Dashboard',
                    route: '/super-admin/dashboard',
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Admin Management',
                    route: '/super-admin/admins',
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.settings_suggest_rounded,
                    title: 'System Settings',
                    route: '/super-admin/settings',
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.history_edu_rounded,
                    title: 'Audit & Activity Log',
                    route: '/super-admin/audit',
                  ),

                  const Divider(height: 24),
                  _buildNavHeader(context, 'QUICK SWITCH'),
                  _buildNavItem(
                    context: context,
                    icon: Icons.storefront_rounded,
                    title: 'Restaurant Admin Panel',
                    route: '/admin/dashboard',
                    isSecondary: true,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.fastfood_rounded,
                    title: 'Customer Storefront',
                    route: '/home',
                    isSecondary: true,
                  ),
                ],
              ),
            ),

            // Bottom Logout
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        title,
        style: TextStyle(
          color: SuperAdminTheme.getTextMuted(context),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    bool isSecondary = false,
  }) {
    final isSelected = currentRoute == route;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected
            ? SuperAdminTheme.primary.withValues(alpha: isDark ? 0.35 : 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(
            icon,
            color: isSelected
                ? SuperAdminTheme.primary
                : SuperAdminTheme.getTextMuted(context),
            size: 22,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13.5,
              color: isSelected
                  ? SuperAdminTheme.primary
                  : SuperAdminTheme.getTextDark(context),
            ),
          ),
          onTap: () {
            Navigator.pop(context); // close drawer
            if (currentRoute != route) {
              if (route == '/super-admin/dashboard') {
                Navigator.of(context).pushNamedAndRemoveUntil('/super-admin/dashboard', (r) => false);
              } else if (route == '/home') {
                Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
              } else if (route == '/admin/dashboard') {
                Navigator.of(context).pushNamed(route);
              } else {
                if (currentRoute == '/super-admin/dashboard') {
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
