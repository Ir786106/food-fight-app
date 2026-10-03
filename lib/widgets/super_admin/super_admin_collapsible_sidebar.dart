import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/super_admin_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../theme/theme_provider.dart';

/// Professional Collapsible Sidebar for Super Admin Platform Portal.
class SuperAdminCollapsibleSidebar extends StatefulWidget {
  final String currentRoute;
  final bool initialCollapsed;
  final Function(bool isCollapsed)? onToggle;

  const SuperAdminCollapsibleSidebar({
    super.key,
    required this.currentRoute,
    this.initialCollapsed = false,
    this.onToggle,
  });

  @override
  State<SuperAdminCollapsibleSidebar> createState() => _SuperAdminCollapsibleSidebarState();
}

class _SuperAdminCollapsibleSidebarState extends State<SuperAdminCollapsibleSidebar> {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final superProvider = context.watch<SuperAdminProvider>();
    final unreadChats = context.watch<ChatProvider>().totalAdminUnread;

    final sidebarBg = isDark ? const Color(0xFF13151A) : const Color(0xFF181B22);
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
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Super Admin Header
            _buildHeader(),

            const Divider(color: Colors.white12, height: 1),

            // Scrollable Navigation
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                children: [
                  _buildSectionTitle('CORE PLATFORM'),
                  _buildNavItem(
                    title: 'System Dashboard',
                    icon: Icons.space_dashboard_rounded,
                    route: '/super-admin/dashboard',
                    activeBg: activeBg,
                    activeTextColor: activeTextColor,
                  ),
                  _buildNavItem(
                    title: '5 Restaurant Branches',
                    icon: Icons.store_mall_directory_rounded,
                    route: '/super-admin/branches',
                    badgeCount: superProvider.totalBranches,
                    badgeColor: AppColors.brandYellow,
                    activeBg: activeBg,
                    activeTextColor: activeTextColor,
                  ),
                  _buildNavItem(
                    title: 'Admins & Staff Access',
                    icon: Icons.admin_panel_settings_rounded,
                    route: '/super-admin/admins',
                    badgeCount: superProvider.totalAdmins,
                    badgeColor: AppColors.brandYellow,
                    activeBg: activeBg,
                    activeTextColor: activeTextColor,
                  ),

                  _buildSectionTitle('PLATFORM OPS'),
                  _buildNavItem(
                    title: 'Global Customer Chat',
                    icon: Icons.mark_chat_unread_rounded,
                    route: '/admin/chats',
                    badgeCount: unreadChats,
                    badgeColor: AppColors.error,
                    activeBg: activeBg,
                    activeTextColor: activeTextColor,
                  ),
                  _buildNavItem(
                    title: 'Platform Deals & Offers',
                    icon: Icons.local_offer_rounded,
                    route: '/admin/deals',
                    activeBg: activeBg,
                    activeTextColor: activeTextColor,
                  ),
                  _buildNavItem(
                    title: 'Fleet & Riders Overview',
                    icon: Icons.two_wheeler_rounded,
                    route: '/admin/riders',
                    activeBg: activeBg,
                    activeTextColor: activeTextColor,
                  ),
                  _buildNavItem(
                    title: 'Rider Console View',
                    icon: Icons.delivery_dining_rounded,
                    route: '/rider/dashboard',
                    activeBg: activeBg,
                    activeTextColor: activeTextColor,
                  ),

                  _buildSectionTitle('GOVERNANCE & AUDIT'),
                  _buildNavItem(
                    title: 'Security Audit Logs',
                    icon: Icons.history_edu_rounded,
                    route: '/super-admin/audit',
                    activeBg: activeBg,
                    activeTextColor: activeTextColor,
                  ),
                  _buildNavItem(
                    title: 'Global System Settings',
                    icon: Icons.tune_rounded,
                    route: '/super-admin/settings',
                    activeBg: activeBg,
                    activeTextColor: activeTextColor,
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Profile & Logout Footer
            _buildFooter(context, user),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SUPER ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'Platform Command HQ',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10.5,
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
                          color: badgeColor ?? AppColors.brandYellow,
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
                          : (badgeColor ?? AppColors.brandYellow),
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

  Widget _buildFooter(BuildContext context, dynamic user) {
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.brandYellow,
            child: Text(
              (user?.name != null && user!.name.isNotEmpty)
                  ? user.name[0].toUpperCase()
                  : 'S',
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
                  user?.name ?? 'Super Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Super Admin',
                  style: TextStyle(
                    color: Colors.white60,
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
    );
  }

  void _confirmSignOut(BuildContext ctx) async {
    final auth = ctx.read<AuthProvider>();
    final nav = Navigator.of(ctx);
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to exit the Super Admin HQ?'),
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
