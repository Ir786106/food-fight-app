import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import 'notch_painter.dart';

/// Navigation item model representing a slot on the floating navigation bar.
class FloatingNavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final String semanticLabel;

  const FloatingNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.semanticLabel,
  });
}

/// Floating bottom navigation bar with a smooth cubic-bezier notch,
/// elevated 60px circular cart button with yellow glow ring, animated sliding dot,
/// unread chat badge, orders-in-progress indicator, and tablet NavigationRail fallback.
class FloatingNavBar extends StatefulWidget {
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

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar>
    with TickerProviderStateMixin {
  late AnimationController _cartPulseController;
  late Animation<double> _cartPulseAnimation;
  int _prevCartCount = 0;

  static const List<FloatingNavItem> _navItems = [
    FloatingNavItem(
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: 'Home',
      semanticLabel: 'Home tab',
    ),
    FloatingNavItem(
      activeIcon: Icons.receipt_long_rounded,
      inactiveIcon: Icons.receipt_long_outlined,
      label: 'Orders',
      semanticLabel: 'Orders tab',
    ),
    FloatingNavItem(
      activeIcon: Icons.shopping_bag_rounded,
      inactiveIcon: Icons.shopping_bag_outlined,
      label: 'Cart',
      semanticLabel: 'Cart button',
    ),
    FloatingNavItem(
      activeIcon: Icons.chat_bubble_rounded,
      inactiveIcon: Icons.chat_bubble_outline_rounded,
      label: 'Chat',
      semanticLabel: 'Support chat tab',
    ),
    FloatingNavItem(
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
      label: 'Profile',
      semanticLabel: 'Profile tab',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cartPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _cartPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(_cartPulseController);
  }

  @override
  void dispose() {
    _cartPulseController.dispose();
    super.dispose();
  }

  void _triggerCartPulse(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!disableAnimations) {
      _cartPulseController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen width for tablet NavigationRail (>= 840px)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 840;

    // Cart count
    int cartCount = widget.explicitCartCount ?? 0;
    try {
      final cart = context.watch<CartProvider?>();
      if (cart != null && widget.explicitCartCount == null) {
        cartCount = cart.itemCount;
      }
    } catch (_) {}

    // Check if new item was added to pulse exactly once
    if (cartCount > _prevCartCount && cartCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _triggerCartPulse(context);
      });
    }
    _prevCartCount = cartCount;

    // Chat unread count
    int chatUnread = widget.explicitChatUnreadCount ?? 0;
    try {
      final chat = context.watch<ChatProvider?>();
      if (chat != null && widget.explicitChatUnreadCount == null) {
        chatUnread = chat.totalCustomerUnread;
      }
    } catch (_) {}

    // Orders active indicator
    bool hasActiveOrder = widget.explicitHasActiveOrder ?? false;
    try {
      final orderProv = context.watch<OrderProvider?>();
      if (orderProv != null && widget.explicitHasActiveOrder == null) {
        hasActiveOrder = orderProv.customerOrders.any(
          (o) =>
              o.status != OrderStatus.delivered &&
              o.status != OrderStatus.cancelled,
        );
      }
    } catch (_) {}

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isTablet) {
      return _buildTabletRail(
        isDark: isDark,
        cartCount: cartCount,
        chatUnread: chatUnread,
        hasActiveOrder: hasActiveOrder,
      );
    }

    return _buildFloatingBar(
      context: context,
      isDark: isDark,
      cartCount: cartCount,
      chatUnread: chatUnread,
      hasActiveOrder: hasActiveOrder,
    );
  }

  Widget _buildFloatingBar({
    required BuildContext context,
    required bool isDark,
    required int cartCount,
    required int chatUnread,
    required bool hasActiveOrder,
  }) {
    const barHeight = 68.0;
    const centerBtnSize = 60.0;
    final navSurface = isDark ? AppColors.darkSurfaceElevated : AppColors.surface;
    final navBorder = isDark ? AppColors.darkBorder : AppColors.border;

    return AnimatedSlide(
      offset: widget.isVisible ? Offset.zero : const Offset(0, 1.6),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: Container(
          height: barHeight + 14,
          margin: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 12,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Notched pill background container
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: barHeight,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: FloatingNavNotchPainter(
                      color: navSurface,
                      borderColor: navBorder,
                      shadowColor: isDark
                          ? Colors.black.withValues(alpha: 0.45)
                          : const Color(0x1F2A1415), // 0 8 24 rgba(42,20,21,0.12)
                      notchRadius: 36.0,
                      notchDepth: 22.0,
                      cornerRadius: 28.0,
                    ),
                    child: SizedBox(
                      height: barHeight,
                      child: Row(
                        children: [
                          // Slot 0: Home
                          Expanded(
                            child: _buildBarTabItem(
                              index: 0,
                              item: _navItems[0],
                              isDark: isDark,
                            ),
                          ),
                          // Slot 1: Orders (with active dot)
                          Expanded(
                            child: _buildBarTabItem(
                              index: 1,
                              item: _navItems[1],
                              isDark: isDark,
                              showDotBadge: hasActiveOrder,
                            ),
                          ),
                          // Slot 2: Space for Center Cart Button
                          const SizedBox(width: centerBtnSize + 12),
                          // Slot 3: Chat (with unread count badge)
                          Expanded(
                            child: _buildBarTabItem(
                              index: 3,
                              item: _navItems[3],
                              isDark: isDark,
                              countBadge: chatUnread,
                            ),
                          ),
                          // Slot 4: Profile
                          Expanded(
                            child: _buildBarTabItem(
                              index: 4,
                              item: _navItems[4],
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Center Raised Cart Button (60px circle, maroon, yellow bag, yellow badge, yellow glow ring)
              Positioned(
                bottom: barHeight - (centerBtnSize / 2) + 4,
                child: ScaleTransition(
                  scale: _cartPulseAnimation,
                  child: Semantics(
                    button: true,
                    label: 'Cart with $cartCount items',
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (widget.onCartSelected != null) {
                            widget.onCartSelected!();
                          } else {
                            widget.onTabSelected(2);
                          }
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: centerBtnSize,
                          height: centerBtnSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.currentIndex == 2
                                ? AppColors.brandYellow
                                : AppColors.brandMaroon,
                            boxShadow: [
                              // Soft yellow glow ring at ~28% opacity (enhanced when selected)
                              BoxShadow(
                                color: AppColors.brandYellow.withValues(
                                  alpha: widget.currentIndex == 2 ? 0.45 : 0.28,
                                ),
                                blurRadius: widget.currentIndex == 2 ? 22 : 18,
                                spreadRadius: widget.currentIndex == 2 ? 4 : 3,
                                offset: const Offset(0, 2),
                              ),
                              // Soft dark shadow underneath
                              BoxShadow(
                                color: AppColors.maroonDeep.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: widget.currentIndex == 2
                                  ? AppColors.brandMaroon
                                  : AppColors.brandYellow,
                              width: 2.5,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag_rounded,
                                color: widget.currentIndex == 2
                                    ? AppColors.brandMaroon
                                    : AppColors.brandYellow,
                                size: 28,
                              ),

                              // Cart Count Badge
                              if (cartCount > 0)
                                Positioned(
                                  top: 1,
                                  right: 1,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: widget.currentIndex == 2
                                          ? AppColors.brandMaroon
                                          : AppColors.brandYellow,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: widget.currentIndex == 2
                                            ? AppColors.brandYellow
                                            : AppColors.brandMaroon,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Center(
                                      child: Text(
                                        cartCount > 99 ? '99+' : '$cartCount',
                                        style: TextStyle(
                                          color: widget.currentIndex == 2
                                              ? AppColors.brandYellow
                                              : AppColors.brandMaroon,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarTabItem({
    required int index,
    required FloatingNavItem item,
    required bool isDark,
    int countBadge = 0,
    bool showDotBadge = false,
  }) {
    final isSelected = widget.currentIndex == index;
    final activeIconColor = isDark ? AppColors.brandYellow : AppColors.brandMaroon;
    final inactiveIconColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTabSelected(index);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Stack with Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isSelected ? item.activeIcon : item.inactiveIcon,
                      size: 24,
                      color: isSelected ? activeIconColor : inactiveIconColor,
                    ),

                    // Dot badge for orders in progress
                    if (showDotBadge)
                      Positioned(
                        top: -1,
                        right: -3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                    // Count badge for chat unread
                    if (countBadge > 0)
                      Positioned(
                        top: -4,
                        right: -9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.tomato,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              countBadge > 99 ? '99+' : '$countBadge',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 2),

                // Text label: ONLY for active item to keep it clean
                if (isSelected)
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: activeIconColor,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  const SizedBox(height: 11),

                const SizedBox(height: 2),

                // 6px yellow dot indicator underneath active item that slides smoothly
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 6.0 : 0.0,
                  height: 6.0,
                  decoration: const BoxDecoration(
                    color: AppColors.brandYellow,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tablet/Web NavigationRail alternative (for screens >= 840 px)
  Widget _buildTabletRail({
    required bool isDark,
    required int cartCount,
    required int chatUnread,
    required bool hasActiveOrder,
  }) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: NavigationRail(
        selectedIndex: widget.currentIndex.clamp(0, 4),
        onDestinationSelected: (idx) {
          HapticFeedback.lightImpact();
          if (idx == 2 && widget.onCartSelected != null) {
            widget.onCartSelected!();
          } else {
            widget.onTabSelected(idx);
          }
        },
        backgroundColor: Colors.transparent,
        labelType: NavigationRailLabelType.selected,
        selectedIconTheme: IconThemeData(
          color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
          size: 26,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textMuted,
          size: 24,
        ),
        selectedLabelTextStyle: TextStyle(
          color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        destinations: [
          const NavigationRailDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: Text('Home'),
          ),
          NavigationRailDestination(
            icon: Badge(
              isLabelVisible: hasActiveOrder,
              backgroundColor: AppColors.brandYellow,
              smallSize: 8,
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: hasActiveOrder,
              backgroundColor: AppColors.brandYellow,
              smallSize: 8,
              child: const Icon(Icons.receipt_long_rounded),
            ),
            label: const Text('Orders'),
          ),
          NavigationRailDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              backgroundColor: AppColors.brandYellow,
              textColor: AppColors.brandMaroon,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              backgroundColor: AppColors.brandYellow,
              textColor: AppColors.brandMaroon,
              child: const Icon(Icons.shopping_bag_rounded),
            ),
            label: const Text('Cart'),
          ),
          NavigationRailDestination(
            icon: Badge(
              isLabelVisible: chatUnread > 0,
              label: Text('$chatUnread'),
              backgroundColor: AppColors.tomato,
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: chatUnread > 0,
              label: Text('$chatUnread'),
              backgroundColor: AppColors.tomato,
              child: const Icon(Icons.chat_bubble_rounded),
            ),
            label: const Text('Chat'),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: Text('Profile'),
          ),
        ],
      ),
    );
  }
}
