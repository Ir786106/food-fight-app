import 'package:flutter/material.dart';
import 'package:food_fight/core/responsive/breakpoints.dart' as resp;
import 'package:food_fight/core/constants/app_colors.dart';
import 'admin_collapsible_sidebar.dart';

/// Responsive Scaffold for Admin and Sub-Admin screens.
/// Adapts seamlessly:
/// - Expanded / Large (>=840px): Permanent full sidebar (260px) collapsible to 72px.
/// - Medium (600-839px): Collapsed NavigationRail icon sidebar (72px) expandable to 260px.
/// - Compact (<600px): Collapsible Drawer + Bottom navigation bar for core sections.
class AdminScaffold extends StatelessWidget {
  final String currentRoute;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const AdminScaffold({
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
        drawer: AdminCollapsibleSidebar(
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
          AdminCollapsibleSidebar(
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
      ('/admin/dashboard', 'Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
      ('/admin/orders', 'Orders', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
      ('/admin/menu', 'Menu', Icons.restaurant_menu_outlined, Icons.restaurant_menu_rounded),
      ('/admin/chats', 'Chats', Icons.chat_bubble_outline_rounded, Icons.chat_rounded),
    ];

    int currentIndex = destinations.indexWhere((d) => d.$1 == currentRoute);
    if (currentIndex == -1) currentIndex = 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NavigationBar(
      selectedIndex: currentIndex,
      height: 62,
      elevation: 4,
      backgroundColor: isDark ? const Color(0xFF1E222B) : Colors.white,
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
