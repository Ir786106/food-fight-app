import '../../core/localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
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
    final navSurface =
        isDark ? AppColors.darkSurfaceElevated : AppColors.surface;
    final navBorder = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      foregroundDecoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: navBorder.withValues(alpha: 0.6)))),
      decoration: BoxDecoration(
        color: navSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
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
        isDark ? AppColors.darkTextMuted : AppColors.textSecondary;
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
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 16 : 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? activePillBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
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

                const SizedBox(height: 2),

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
    final railSurface =
        isDark ? AppColors.darkSurfaceElevated : AppColors.surface;
    final railBorder = isDark ? AppColors.darkBorder : AppColors.border;
    final activeColor = isDark ? AppColors.brandYellow : AppColors.brandMaroon;

    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: railSurface,
        border: BorderDirectional(
          end: BorderSide(
            color: railBorder.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Brand Logo mark
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.brandYellow,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandYellow.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'FF',
                  style: TextStyle(
                    color: AppColors.brandMaroon,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Rail Destinations
            Expanded(
              child: ListView.separated(
                itemCount: _destinations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = _destinations[index];
                  final isSelected = currentIndex == index;

                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTabSelected(index);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                              ? AppColors.brandYellow
                                              : AppColors.brandMaroon)
                                          .withValues(
                                              alpha: isDark ? 0.2 : 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isSelected
                                      ? item.activeIcon
                                      : item.inactiveIcon,
                                  size: 24,
                                  color: isSelected
                                      ? activeColor
                                      : (isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.textSecondary),
                                ),
                              ),
                              if (index == 2 && chatUnread > 0)
                                PositionedDirectional(
                                  top: -2,
                                  end: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandMaroon,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      chatUnread > 99 ? '99+' : '$chatUnread',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              if (index == 1 && hasActiveOrder)
                                PositionedDirectional(
                                  top: 0,
                                  end: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.brandYellow,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(item.label),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? activeColor
                                  : (isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
