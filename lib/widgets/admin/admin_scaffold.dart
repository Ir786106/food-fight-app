import 'package:flutter/material.dart';
import '../common/responsive_layout.dart';
import 'admin_collapsible_sidebar.dart';

/// Responsive Scaffold for Admin and Sub-Admin screens.
/// Adapts seamlessly:
/// - Desktop (>1024px): Permanent full sidebar (260px) collapsible to 72px.
/// - Tablet (600-1024px): Collapsed icon sidebar (72px) expandable to 260px.
/// - Mobile (<600px): Drawer + standard app bar.
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
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);

    if (isMobile) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        drawer: AdminCollapsibleSidebar(
          currentRoute: currentRoute,
          initialCollapsed: false,
        ),
        body: body,
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
            initialCollapsed: isTablet,
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
}
