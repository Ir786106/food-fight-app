import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

/// Navigation tab item model for FloatingNotchNavBar
class NavTabItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final String semanticLabel;

  const NavTabItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.semanticLabel,
  });
}

/// Floating, pill-shaped bottom navigation bar with a smooth custom-painted
/// center notch, animated tab selection, and a elevated circular center action button.
class FloatingNotchNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCenterAction;
  final int centerBadgeCount;
  final List<NavTabItem> tabs;

  const FloatingNotchNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCenterAction,
    this.centerBadgeCount = 0,
    required this.tabs,
  }) : assert(tabs.length == 4, 'FloatingNotchNavBar expects exactly 4 tabs (2 on each side)');

  @override
  State<FloatingNotchNavBar> createState() => _FloatingNotchNavBarState();
}

class _FloatingNotchNavBarState extends State<FloatingNotchNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _centerButtonAnimController;
  late Animation<double> _centerButtonScaleAnim;

  @override
  void initState() {
    super.initState();
    _centerButtonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _centerButtonScaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _centerButtonAnimController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _centerButtonAnimController.dispose();
    super.dispose();
  }

  void _handleTabTap(int targetIndex) {
    if (widget.currentIndex == targetIndex) return;
    HapticFeedback.selectionClick();
    widget.onTabSelected(targetIndex);
  }

  void _handleCenterTap() {
    HapticFeedback.selectionClick();
    _centerButtonAnimController.forward().then((_) {
      _centerButtonAnimController.reverse();
    });
    widget.onCenterAction();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Palette variants
    final navBarBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final navBorder = isDark ? AppColors.darkBorder : AppColors.border;

    const barHeight = AppDimens.navBarHeight;
    const centerBtnSize = AppDimens.navBarCenterButtonSize;

    return SafeArea(
      bottom: true,
      top: false,
      child: Container(
        height: barHeight + 16,
        margin: const EdgeInsets.only(
          left: AppDimens.navBarHorizontalMargin,
          right: AppDimens.navBarHorizontalMargin,
          bottom: AppDimens.navBarBottomMargin,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Pill container with custom notched background
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: barHeight,
              child: CustomPaint(
                painter: _NotchedPillPainter(
                  color: navBarBg,
                  borderColor: navBorder,
                  shadowColor: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : AppColors.maroonDeep.withValues(alpha: 0.08),
                  notchRadius: 33.0,
                ),
                child: SizedBox(
                  height: barHeight,
                  child: Row(
                    children: [
                      // Left 2 tabs
                      Expanded(child: _buildTabButton(0, widget.tabs[0], isDark)),
                      Expanded(child: _buildTabButton(1, widget.tabs[1], isDark)),

                      // Center notch spacing
                      const SizedBox(width: centerBtnSize + 12),

                      // Right 2 tabs
                      Expanded(child: _buildTabButton(2, widget.tabs[2], isDark)),
                      Expanded(child: _buildTabButton(3, widget.tabs[3], isDark)),
                    ],
                  ),
                ),
              ),
            ),

            // Elevated Center Action (Cart button with halo and live badge)
            Positioned(
              bottom: barHeight - (centerBtnSize / 2) + 2,
              child: ScaleTransition(
                scale: _centerButtonScaleAnim,
                child: GestureDetector(
                  onTap: _handleCenterTap,
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    button: true,
                    label: 'Cart with ${widget.centerBadgeCount} items',
                    child: Container(
                      width: centerBtnSize,
                      height: centerBtnSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandMaroon,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.maroonDeep.withValues(alpha: 0.38),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: AppColors.brandYellow.withValues(alpha: 0.25),
                            blurRadius: 10,
                            spreadRadius: -1,
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.brandYellow,
                          width: 2.5,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Subtle dotted / ring halo effect
                          CustomPaint(
                            size: const Size(centerBtnSize, centerBtnSize),
                            painter: _RingHaloPainter(),
                          ),

                          // Shopping Bag Icon
                          const Icon(
                            Icons.shopping_bag_rounded,
                            color: AppColors.brandYellow,
                            size: 26,
                          ),

                          // Live Badge Pill
                          if (widget.centerBadgeCount > 0)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brandYellow,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.brandMaroon,
                                    width: 1.5,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    widget.centerBadgeCount > 99
                                        ? '99+'
                                        : '${widget.centerBadgeCount}',
                                    style: const TextStyle(
                                      color: AppColors.onYellow,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, NavTabItem tab, bool isDark) {
    final isSelected = widget.currentIndex == index;
    final activeColor = isDark ? AppColors.brandYellow : AppColors.brandMaroon;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Semantics(
      button: true,
      selected: isSelected,
      label: tab.semanticLabel,
      child: InkWell(
        onTap: () => _handleTabTap(index),
        splashColor: AppColors.yellowSoft.withValues(alpha: 0.2),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radius24),
        child: SizedBox(
          height: AppDimens.navBarHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with subtle scale on select
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.0, end: isSelected ? 1.12 : 1.0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Icon(
                      isSelected ? tab.activeIcon : tab.inactiveIcon,
                      size: 24,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  );
                },
              ),

              const SizedBox(height: 3),

              // Label
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 3),

              // Small brand-colored dot indicator under active tab
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: isSelected ? 4.5 : 0,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandYellow : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter rendering a smooth pill outline with a circular notch at the top center
class _NotchedPillPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final double notchRadius;

  const _NotchedPillPainter({
    required this.color,
    required this.borderColor,
    required this.shadowColor,
    required this.notchRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final radius = h / 2; // Pill rounded corners
    final cx = w / 2;

    // Draw shadow first
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    final path = Path();
    const s = 14.0; // notch transition smoothness

    // Start at top-left, after the corner radius
    path.moveTo(radius, 0);

    // Line towards center notch
    path.lineTo(cx - notchRadius - s, 0);

    // Smooth cubic bezier down into the notch
    path.cubicTo(
      cx - notchRadius, 0,
      cx - notchRadius, notchRadius * 0.72,
      cx, notchRadius * 0.72,
    );

    // Smooth cubic bezier out of the notch
    path.cubicTo(
      cx + notchRadius, notchRadius * 0.72,
      cx + notchRadius, 0,
      cx + notchRadius + s, 0,
    );

    // Line to top-right corner
    path.lineTo(w - radius, 0);

    // Right pill semi-circle
    path.arcToPoint(
      Offset(w - radius, h),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Bottom line
    path.lineTo(radius, h);

    // Left pill semi-circle
    path.arcToPoint(
      Offset(radius, 0),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    path.close();

    // Canvas draws shadow, fill, then border
    canvas.drawPath(path.shift(const Offset(0, 6)), shadowPaint);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _NotchedPillPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.notchRadius != notchRadius;
  }
}

/// Painter for the subtle concentric ring accent inside the center button
class _RingHaloPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppColors.brandYellow.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, (size.width / 2) - 4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
