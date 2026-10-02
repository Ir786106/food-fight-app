import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';

/// Global floating dark pill cart bar following Reference A.
/// Features:
/// - maroonDeep #4A1517 background, radius 28
/// - Left yellow rounded-square with shopping bag icon
/// - Live count ("N items") and formatted total
/// - Right "View cart" with arrow
/// - Smooth slide up/down animation (250 ms)
/// - Tap opens the cart screen
class FloatingCartBar extends StatelessWidget {
  final VoidCallback? onTap;
  final double bottomOffset;

  const FloatingCartBar({
    super.key,
    this.onTap,
    this.bottomOffset = 84.0, // Clearance above the floating bottom nav bar
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final hasItems = cart.itemCount > 0;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Do not display if keyboard is active or cart is empty
    final isVisible = hasItems && !keyboardOpen;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      left: 16,
      right: 16,
      bottom: isVisible ? bottomOffset : -80.0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1.0 : 0.0,
        child: Semantics(
          button: true,
          label: 'View cart with ${cart.itemCount} items, total Rs. ${cart.total.toStringAsFixed(0)}',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isVisible
                  ? () {
                      HapticFeedback.lightImpact();
                      if (onTap != null) {
                        onTap!();
                      } else {
                        Navigator.of(context).pushNamed('/cart');
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.maroonDeep, // MaroonDeep #4A1517
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.maroonDeep.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: AppColors.brandYellow.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.brandYellow.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    // Left yellow rounded-square with bag icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.brandYellow,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandYellow.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: AppColors.brandMaroon,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Count and Subtotal text with count animation
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              TweenAnimationBuilder<double>(
                                key: ValueKey(cart.itemCount),
                                tween: Tween<double>(begin: 0.8, end: 1.0),
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutBack,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${cart.itemCount} ${cart.itemCount == 1 ? "item" : "items"}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppColors.yellowSoft,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rs. ${cart.total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.brandYellow,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Fresh & Hot Food Delivery',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right "View cart" with arrow
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.brandYellow,
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
