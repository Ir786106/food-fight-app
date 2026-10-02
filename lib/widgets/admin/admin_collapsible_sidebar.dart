import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../theme/theme_provider.dart';

class AdminCollapsibleSidebar extends StatefulWidget {
  final String currentRoute;
  final bool initialCollapsed;
  final Function(bool isCollapsed)? onToggle;

  const AdminCollapsibleSidebar({
    super.key,
    required this.currentRoute,
    this.initialCollapsed = false,
    this.onToggle,
  });

  @override
  State<AdminCollapsibleSidebar> createState() => _AdminCollapsibleSidebarState();
}

class _AdminCollapsibleSidebarState extends State<AdminCollapsibleSidebar> {
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initialCollapsed;
  }

  void _toggleSidebar() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
    widget.onToggle?.call(_isCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final unreadChats = context.watch<ChatProvider>().totalAdminUnread;
    final pendingOrders = context.watch<OrderProvider>().activeOrdersCount;

    final sidebarBg = isDark ? const Color(0xFF16181D) : const Color(0xFF1E222B);
    const textColor = Colors.white;
    final subtextColor = Colors.white.withValues(alpha: 0.65);
    const activeBg = AppColors.brandYellow;
    const activeTextColor = AppColors.onYellow;

    final width = _isCollapsed ? 72.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: sidebarBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(3, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Header: Branding + Branch Badge + Collapse Toggle
            _buildHeader(textColor, subtextColor, user?.branchId),

            const Divider(color: Colors.white12, height: 1),

            // Navigation Menu (Scrollable)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                children: [
                  // OVERVIEW
                  _buildSectionTitle('OVERVIEW'),
                  _buildNavItem(
                    title: 'Dashboard',
                    icon: Icons.dashboard_rounded,
                    route: '/admin/dashboard',
                    activeBg: activeBg,
                    activeTextColor: activeTextColor,
                  ),

                  // ORDERS & LIVE OPS
                  if (user == null || user.can('orders') || user.can('chats')) ...[
                    _buildSectionTitle('OPERATIONS'),
                    if (user == null || user.can('orders'))
                      _buildNavItem(
                        title: 'Orders & Kitchen',
                        icon: Icons.receipt_long_rounded,
                        route: '/admin/orders',
                        badgeCount: pendingOrders,
                        badgeColor: AppColors.primaryYellow,
                        activeBg: activeBg,
                        activeTextColor: activeTextColor,
                      ),
                    if (user == null || user.can('chats'))
                      _buildNavItem(
                        title: 'Live Chat Support',
                        icon: Icons.chat_rounded,
                        route: '/admin/chats',
                        badgeCount: unreadChats,
                        badgeColor: AppColors.error,
                        activeBg: activeBg,
                        activeTextColor: activeTextColor,
                      ),
                  ],

                  // MENU, DEALS & TEMPLATES
                  if (user == null || user.can('menu') || user.can('categories') || user.can('coupons')) ...[
                    _buildSectionTitle('MENU & OFFERS'),
                    if (user == null || user.can('menu'))
                      _buildNavItem(
                        title: 'Menu Items',
                        icon: Icons.restaurant_menu_rounded,
                        route: '/admin/menu',
                        activeBg: activeBg,
                        activeTextColor: activeTextColor,
                      ),
                    if (user == null || user.can('categories'))
                      _buildNavItem(
                        title: 'Categories',
                        icon: Icons.category_rounded,
                        route: '/admin/categories',
                        activeBg: activeBg,
                        activeTextColor: activeTextColor,
                      ),
                    if (user == null || user.can('coupons'))
                      _buildNavItem(
                        title: 'Branch Deals',
                        icon: Icons.local_offer_rounded,
                        route: '/admin/deals',
                        activeBg: activeBg,
                        activeTextColor: activeTextColor,
                      ),
                  ],

                  // CUSTOMERS, LOYALTY & REVIEWS
                  if (user == null || user.can('customers') || user.can('reports')) ...[
                    _buildSectionTitle('CUSTOMERS & FEEDBACK'),
                    if (user == null || user.can('customers'))
                      _buildNavItem(
                        title: 'Customers',
                        icon: Icons.people_alt_rounded,
                        route: '/admin/customers',
                        activeBg: activeBg,
                        activeTextColor: activeTextColor,
                      ),
                    _buildNavItem(
                      title: 'Customer Reviews',
                      icon: Icons.rate_review_rounded,
                      route: '/admin/reviews',
                      activeBg: activeBg,
                      activeTextColor: activeTextColor,
                    ),
                  ],

                  // FLEET & LOGISTICS
                  if (user == null || user.can('delivery_areas') || user.can('riders')) ...[
                    _buildSectionTitle('DELIVERY FLEET'),
                    if (user == null || user.can('riders'))
                      _buildNavItem(
                        title: 'Delivery Riders',
                        icon: Icons.delivery_dining_rounded,
                        route: '/admin/riders',
                        activeBg: activeBg,
                        activeTextColor: activeTextColor,
                      ),
                    if (user == null || user.can('delivery_areas'))
                      _buildNavItem(
                        title: 'Delivery Areas & Rates',
                        icon: Icons.map_rounded,
                        route: '/admin/delivery-areas',
                        activeBg: activeBg,
                        activeTextColor: activeTextColor,
                      ),
                  ],

                  // REPORTS & STAFF
                  if (user == null || user.can('reports') || !user.isSubAdmin) ...[
                    _buildSectionTitle('INSIGHTS & STAFF'),
                    if (user == null || user.can('reports'))
                      _buildNavItem(
                        title: 'Sales & Reports',
                        icon: Icons.insights_rounded,
                        route: '/admin/reports',
                        activeBg: activeBg,
                        activeTextColor: activeTextColor,
                      ),
                    if (user != null && !user.isSubAdmin)
                      _buildNavItem(
                        title: 'Sub-Admin Permissions',
                        icon: Icons.admin_panel_settings_rounded,
                        route: '/admin/sub-admins',
                        activeBg: activeBg,
                        activeTextColor: activeTextColor,
                      ),
                  ],
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Footer Profile & Logout
            _buildFooter(context, user, textColor, subtextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color subtextColor, String? branchId) {
    if (_isCollapsed) {
      return Container(
        height: 70,
        alignment: Alignment.center,
        child: IconButton(
          icon: const Icon(Icons.menu_open_rounded, color: Colors.white),
          tooltip: 'Expand Sidebar',
          onPressed: _toggleSidebar,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: Image.asset(AppConstants.logoIconPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'FOOD FIGHT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  branchId != null && branchId.isNotEmpty ? 'Branch: $branchId' : 'Management Portal',
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white70, size: 20),
            tooltip: 'Collapse Sidebar',
            onPressed: _toggleSidebar,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    if (_isCollapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(color: Colors.white10, thickness: 1, indent: 16, endIndent: 16),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 14, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String title,
    required IconData icon,
    required String route,
    required Color activeBg,
    required Color activeTextColor,
    int? badgeCount,
    Color? badgeColor,
  }) {
    final isSelected = widget.currentRoute == route;

    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.brandYellow.withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: _isCollapsed ? 0 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment:
                _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected ? activeTextColor : Colors.white70,
                  ),
                  if (_isCollapsed && badgeCount != null && badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: badgeColor ?? AppColors.primaryYellow,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (!_isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? activeTextColor : Colors.white,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.black.withValues(alpha: 0.25)
                          : (badgeColor ?? AppColors.primaryYellow),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: TextStyle(
                        color: isSelected ? activeTextColor : Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );

    if (_isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Tooltip(
          message: title,
          preferBelow: false,
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: content,
    );
  }

  Widget _buildFooter(BuildContext context, dynamic user, Color textColor, Color subtextColor) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    if (_isCollapsed) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Colors.white70,
                size: 20,
              ),
              tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
              onPressed: () => themeProvider.toggleTheme(),
            ),
            const SizedBox(height: 6),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              tooltip: 'Sign Out',
              onPressed: () => _confirmSignOut(context),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.brandYellow,
                child: Text(
                  (user?.name != null && user!.name.isNotEmpty)
                      ? user.name[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                    color: AppColors.onYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Branch Manager',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.isSubAdmin == true ? 'Sub-Admin' : 'Branch Admin',
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                tooltip: 'Toggle Theme',
                onPressed: () => themeProvider.toggleTheme(),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                tooltip: 'Log out',
                onPressed: () => _confirmSignOut(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext ctx) async {
    final auth = ctx.read<AuthProvider>();
    final nav = Navigator.of(ctx);
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to end your administrative session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await auth.signOut();
      if (mounted) {
        nav.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}
