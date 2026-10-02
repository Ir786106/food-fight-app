import 'package:flutter/material.dart';
import '../common/responsive_layout.dart';
import 'super_admin_collapsible_sidebar.dart';

/// Responsive Scaffold for Super Admin Platform Portal screens.
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
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);

    if (isMobile) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        drawer: SuperAdminCollapsibleSidebar(
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
          SuperAdminCollapsibleSidebar(
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
