import '../../core/localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_insets.dart';
import '../../providers/chat_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

/// Navigation item model representing a slot on the navigation bar.
class NavDestinationItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final String semanticLabel;

  const NavDestinationItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.semanticLabel,
  });
}

/// Flat, modern, production-grade bottom navigation bar for Food Fight.
/// Features:
/// - 4 primary customer destinations: Home, Orders, Chat, Profile
/// - Anchored flush to screen bottom (respects gesture and 3-button navigation)
/// - Real-time unread chat badge and active orders indicator
/// - High-contrast accessible active pill indicator
/// - Large font scale and small phone safe layouts (FittedBox/ellipsis)
/// - Responsive NavigationRail fallback for tablets (>= 840px)
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onCartSelected;
  final bool isVisible;
  final int? explicitCartCount;
  final int? explicitChatUnreadCount;
  final bool? explicitHasActiveOrder;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.onCartSelected,
    this.isVisible = true,
    this.explicitCartCount,
    this.explicitChatUnreadCount,
    this.explicitHasActiveOrder,
  });

  static const List<NavDestinationItem> _destinations = [
    NavDestinationItem(
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: 'Home',
      semanticLabel: 'Home tab',
    ),
    NavDestinationItem(
      activeIcon: Icons.receipt_long_rounded,
      inactiveIcon: Icons.receipt_long_outlined,
      label: 'Orders',
      semanticLabel: 'Orders tab',
    ),
    NavDestinationItem(
      activeIcon: Icons.chat_bubble_rounded,
      inactiveIcon: Icons.chat_bubble_outline_rounded,
      label: 'Chat',
      semanticLabel: 'Support chat tab',
    ),
    NavDestinationItem(
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
      label: 'Profile',
      semanticLabel: 'Profile tab',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 840;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Chat unread count
    int chatUnread = explicitChatUnreadCount ?? 0;
    try {
      final chat = context.watch<ChatProvider?>();
      if (chat != null && explicitChatUnreadCount == null) {
        chatUnread = chat.totalCustomerUnread;
      }
    } catch (_) {}

    // Orders active indicator
    bool hasActiveOrder = explicitHasActiveOrder ?? false;
    try {
      final orderProv = context.watch<OrderProvider?>();
      if (orderProv != null && explicitHasActiveOrder == null) {
        hasActiveOrder = orderProv.customerOrders.any(
          (o) =>
              o.status != OrderStatus.delivered &&
              o.status != OrderStatus.cancelled,
        );
      }
    } catch (_) {}

    if (isTablet) {
      return _buildTabletRail(
        context: context,
        isDark: isDark,
        chatUnread: chatUnread,
        hasActiveOrder: hasActiveOrder,
      );
    }

    return _buildBottomBar(
      context: context,
      isDark: isDark,
      chatUnread: chatUnread,
      hasActiveOrder: hasActiveOrder,
    );
  }

  Widget _buildBottomBar({
    required BuildContext context,
    required bool isDark,
    required int chatUnread,
    required bool hasActiveOrder,
  }) {
    final navSurface = Theme.of(context).colorScheme.surface;
    final navBorder = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: navSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: navBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: SizedBox(
          height: AppInsets.navBarHeight,
          child: Row(
            children: List.generate(_destinations.length, (index) {
              final item = _destinations[index];
              final isSelected = currentIndex == index;

              return Expanded(
                child: _buildBarItem(
                  context: context,
                  index: index,
                  item: item,
                  isSelected: isSelected,
                  isDark: isDark,
                  countBadge: index == 2 ? chatUnread : 0,
                  showDotBadge: index == 1 && hasActiveOrder,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildBarItem({
    required BuildContext context,
    required int index,
    required NavDestinationItem item,
    required bool isSelected,
    required bool isDark,
    int countBadge = 0,
    bool showDotBadge = false,
  }) {
    final activeColor = isDark ? AppColors.brandYellow : AppColors.brandMaroon;
    final inactiveColor =
        Theme.of(context).colorScheme.onSurfaceVariant;
    final activePillBg =
        (isDark ? AppColors.brandYellow : AppColors.brandMaroon)
            .withValues(alpha: isDark ? 0.18 : 0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTabSelected(index);
        },
        child: Semantics(
          selected: isSelected,
          button: true,
          label: context.tr(item.semanticLabel),
          child: SizedBox(
            height: AppInsets.navBarHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with active pill and badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? activePillBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.inactiveIcon,
                        size: 24,
                        color: isSelected ? activeColor : inactiveColor,
                      ),

                      // Number badge for unread chat
                      if (countBadge > 0)
                        PositionedDirectional(
                          top: -4,
                          end: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.brandMaroon,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkSurfaceElevated
                                    : Colors.white,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            child: Text(
                              countBadge > 99 ? '99+' : countBadge.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                      // Active orders pulsing dot
                      if (showDotBadge)
                        PositionedDirectional(
                          top: -2,
                          end: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.brandYellow,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkSurfaceElevated
                                    : Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandYellow
                                      .withValues(alpha: 0.6),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Label
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.tr(item.label),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? activeColor : inactiveColor,
                      letterSpacing: isSelected ? 0.1 : 0,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletRail({
    required BuildContext context,
    required bool isDark,
    required int chatUnread,
    required bool hasActiveOrder,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = isDark ? AppColors.brandYellow : AppColors.brandMaroon;

    return Container(
      width: 184,
      decoration: BoxDecoration(
        color: colors.surface,
        border: BorderDirectional(end: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(AppConstants.logoPath, width: 38, height: 38),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Food Fight',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  final item = _destinations[index];
                  final selected = index == currentIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      minLeadingWidth: 24,
                      selected: selected,
                      selectedColor: accent,
                      selectedTileColor: accent.withValues(alpha: 0.12),
                      leading: Badge(
                        isLabelVisible:
                            (index == 2 && chatUnread > 0) ||
                            (index == 1 && hasActiveOrder),
                        label: index == 2
                            ? Text(chatUnread > 99 ? '99+' : '$chatUnread')
                            : null,
                        child: Icon(selected ? item.activeIcon : item.inactiveIcon),
                      ),
                      title: Text(
                        context.tr(item.label),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => onTabSelected(index),
                    ),
                  );
                },
                ),
              ),
            ),
            if (onCartSelected != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton.icon(
                  onPressed: onCartSelected,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: Text(context.tr('Cart')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
