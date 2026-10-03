import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_model.dart';
import '../../providers/cart_provider.dart';
import '../common/network_image_view.dart';
import '../menu/item_customization_bottom_sheet.dart';

/// Product card widget following Reference A.
/// Features:
/// - Rounded card (radius 24) with soft drop shadow
/// - Circular food image overlapping card top by ~40% with a blurred shadow underneath
/// - Name (bold 16), subtitle (textSecondary 12, single line ellipsis)
/// - Maroon bold price, strike-through original price if discounted, mustard rating, and lettuce veg dot
/// - 44x44 yellow rounded-square add button (radius 14) with scale feedback
/// - Opens customization sheet if item has required variants/options
/// - Desaturated unavailable state when out of stock
class ProductCard extends StatefulWidget {
  final FoodModel food;
  final VoidCallback onTap;
  final String? heroTag;
  final double width;
  final bool isHorizontalInList;

  const ProductCard({
    super.key,
    required this.food,
    required this.onTap,
    this.heroTag,
    this.width = 176.0,
    this.isHorizontalInList = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleAddTap(BuildContext context, CartProvider cart) {
    HapticFeedback.lightImpact();

    // Check if item has required options (variants/sizes)
    final hasRequiredOptions = widget.food.hasVariants ||
        (widget.food.variants != null && widget.food.variants!.isNotEmpty);

    if (hasRequiredOptions) {
      ItemCustomizationBottomSheet.show(context, widget.food);
      return;
    }

    // Single item instant add
    _scaleController.forward().then((_) => _scaleController.reverse());

    if (cart.isDifferentBranch(widget.food.branchId)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Start New Order?'),
          content: const Text(
            'Your cart contains items from a different branch. Adding this item will start a fresh cart for this branch.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandYellow,
                foregroundColor: AppColors.onYellow,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                cart.clearCart();
                cart.addToCart(widget.food);
              },
              child: const Text(
                'Start New Cart',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onYellow),
              ),
            ),
          ],
        ),
      );
      return;
    }

    cart.addToCart(widget.food);
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isAvailable = food.isAvailable;
    final effectiveHeroTag = widget.heroTag ?? 'food-${food.id}';
    final cardWidth = widget.width;
    final photoDiameter = cardWidth * 0.62;

    final hasMultipleVariants = (food.variants != null && food.variants!.length > 1) ||
        (food.sizePrices != null && food.sizePrices!.length > 1);

    final hasRequiredOptions = food.hasVariants ||
        (food.variants != null && food.variants!.isNotEmpty);

    final displayPrice = hasMultipleVariants
        ? 'Rs. ${food.startingPrice.toStringAsFixed(0)}'
        : 'Rs. ${food.price.toStringAsFixed(0)}';

    return Semantics(
      button: true,
      label: '${food.name}, price $displayPrice',
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(top: 18, bottom: 8, right: 14),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // 1. Rounded Card Body (surface color, radius 24, soft shadow)
            GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: cardWidth,
                margin: EdgeInsets.only(top: photoDiameter * 0.35),
                padding: EdgeInsets.fromLTRB(
                  12,
                  (photoDiameter * 0.65) + 6,
                  12,
                  10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.40)
                          : AppColors.maroonDeep.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Veg indicator & Rating Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (food.isVeg)
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.lettuce, width: 1.2),
                            ),
                            child: const Icon(
                              Icons.circle,
                              color: AppColors.lettuce,
                              size: 7,
                            ),
                          )
                        else
                          const SizedBox.shrink(),

                        // Rating badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.border,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.mustard, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                food.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Food Name (bold 16)
                    Text(
                      food.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 3),

                    // Subtitle (textSecondary 12, one line ellipsis)
                    Text(
                      food.description,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 10),

                    // Bottom Row: Price & Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasMultipleVariants)
                                Text(
                                  'From',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                displayPrice,
                                style: const TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.brandMaroon, // Mandatory contrast
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Add Button: 44x44 yellow rounded-square (radius 14) with maroon bag/plus
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Semantics(
                            button: true,
                            enabled: isAvailable,
                            label: 'Add ${food.name} to cart',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isAvailable
                                    ? () => _handleAddTap(context, cart)
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? AppColors.brandYellow
                                        : (isDark
                                            ? AppColors.darkSurfaceElevated
                                            : AppColors.surfaceMuted),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: isAvailable
                                        ? [
                                            BoxShadow(
                                              color: AppColors.brandYellow
                                                  .withValues(alpha: 0.38),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    hasRequiredOptions
                                        ? Icons.tune_rounded
                                        : Icons.shopping_bag_outlined,
                                    color: isAvailable
                                        ? AppColors.brandMaroon
                                        : (isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.textMuted),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. Overlapping Circular Food Photo with blurred soft shadow
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Hero(
                  tag: effectiveHeroTag,
                  child: Container(
                    width: photoDiameter,
                    height: photoDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.55)
                              : AppColors.maroonDeep.withValues(alpha: 0.16),
                          blurRadius: 18,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: ColorFiltered(
                        colorFilter: isAvailable
                            ? const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.multiply,
                              )
                            : const ColorFilter.matrix(<double>[
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0,      0,      0,      1, 0,
                              ]),
                        child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                            ? NetworkImageView(
                                imageUrl: food.imageUrl,
                                width: photoDiameter,
                                height: photoDiameter,
                                fit: BoxFit.cover,
                                fallbackEmoji: food.imageEmoji,
                              )
                            : Container(
                                color: isDark
                                    ? AppColors.darkSurfaceElevated
                                    : AppColors.surfaceMuted,
                                alignment: Alignment.center,
                                child: Text(
                                  food.imageEmoji,
                                  style: TextStyle(fontSize: photoDiameter * 0.48),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Unavailable Chip
            if (!isAvailable)
              Positioned(
                top: photoDiameter * 0.40 + 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.maroonDeep.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Unavailable',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
