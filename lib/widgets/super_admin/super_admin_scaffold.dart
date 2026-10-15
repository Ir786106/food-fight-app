import 'package:flutter/material.dart';
import 'package:food_fight/core/responsive/breakpoints.dart' as resp;
import 'package:food_fight/core/constants/app_colors.dart';
import 'super_admin_collapsible_sidebar.dart';

/// Responsive Scaffold for Super Admin Platform Portal screens.
/// Adapts seamlessly:
/// - Expanded / Large (>=840px): Permanent full sidebar (260px) collapsible to 72px.
/// - Medium (600-839px): Collapsed NavigationRail icon sidebar (72px) expandable to 260px.
/// - Compact (<600px): Collapsible Drawer + Bottom navigation bar for core sections.
class SuperAdminScaffold extends StatelessWidget {
  final String currentRoute;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const SuperAdminScaffold({
    super.key,
    required this.currentRoute,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final sizeClass = resp.WindowSizeClass.of(context);
    final isCompact = sizeClass == resp.WindowSizeClass.compact;
    final isMedium = sizeClass == resp.WindowSizeClass.medium;

    if (isCompact) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        drawer: SuperAdminCollapsibleSidebar(
          currentRoute: currentRoute,
          initialCollapsed: false,
        ),
        body: body,
        bottomNavigationBar: _buildBottomBar(context),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          SuperAdminCollapsibleSidebar(
            currentRoute: currentRoute,
            initialCollapsed: isMedium,
          ),
          Expanded(
            child: Scaffold(
              backgroundColor: backgroundColor,
              appBar: appBar,
              body: body,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(BuildContext context) {
    const destinations = [
      ('/super-admin/dashboard', 'HQ', Icons.dashboard_outlined, Icons.dashboard_rounded),
      ('/super-admin/admins', 'Admins', Icons.admin_panel_settings_outlined, Icons.admin_panel_settings_rounded),
      ('/super-admin/audit', 'Audit', Icons.history_outlined, Icons.history_rounded),
      ('/super-admin/settings', 'Settings', Icons.settings_outlined, Icons.settings_rounded),
    ];

    int currentIndex = destinations.indexWhere((d) => d.$1 == currentRoute);
    if (currentIndex == -1) currentIndex = 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NavigationBar(
      selectedIndex: currentIndex,
      height: 62,
      elevation: 4,
      backgroundColor: isDark ? const Color(0xFF13151A) : Colors.white,
      indicatorColor: AppColors.brandYellow.withValues(alpha: 0.35),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        final targetRoute = destinations[index].$1;
        if (targetRoute != currentRoute) {
          Navigator.of(context).pushReplacementNamed(targetRoute);
        }
      },
      destinations: destinations.map((d) {
        return NavigationDestination(
          icon: Icon(d.$3, size: 22, color: isDark ? Colors.white70 : Colors.black87),
          selectedIcon: Icon(d.$4, size: 22, color: isDark ? Colors.white : AppColors.onYellow),
          label: d.$2,
        );
      }).toList(),
    );
  }
}
