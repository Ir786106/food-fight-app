import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';
import '../models/food_model.dart';
import '../providers/cart_provider.dart';
import 'common/network_image_view.dart';
import 'menu/item_customization_bottom_sheet.dart';

/// Redesigned premium product card following Ref A:
/// - Soft rounded card (radius ~24)
/// - Circular food photo with soft drop shadow
/// - Bold title + short muted subtitle
/// - WCAG AA compliant price
/// - Rounded-square yellow "add to bag" button at bottom-right
/// Supports both horizontal list row style and vertical overflow card style.
class FoodCard extends StatelessWidget {
  final FoodModel food;
  final VoidCallback onTap;
  final String? heroTag;
  final bool isVertical;

  const FoodCard({
    super.key,
    required this.food,
    required this.onTap,
    this.heroTag,
    this.isVertical = false,
  });

  const FoodCard.vertical({
    super.key,
    required this.food,
    required this.onTap,
    this.heroTag,
  }) : isVertical = true;

  @override
  Widget build(BuildContext context) {
    if (isVertical) {
      return _buildVerticalCard(context);
    }
    return _buildHorizontalCard(context);
  }

  Widget _buildVerticalCard(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const cardWidth = 172.0;
    const photoDiameter = 96.0;
    final effectiveTag = heroTag ?? (food.id.isNotEmpty ? 'food-vert-${food.id}' : null);

    final hasMultipleVariants = (food.variants != null && food.variants!.length > 1) ||
        (food.sizePrices != null && food.sizePrices!.length > 1);

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(top: 20, bottom: 8, right: 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // White/Dark Rounded Card Body
          Container(
            width: cardWidth,
            margin: const EdgeInsets.only(top: 40),
            padding: const EdgeInsets.fromLTRB(12, 54, 12, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.foodCardRadius),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 1,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : AppDimens.softShadow(color: AppColors.maroonDeep, opacity: 0.07),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Food Name
                Text(
                  food.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 3),

                // Subtitle / Description
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

                // Bottom row: Price + Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasMultipleVariants)
                            Text(
                              'From',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            hasMultipleVariants
                                ? 'Rs. ${food.startingPrice.toStringAsFixed(0)}'
                                : 'Rs. ${food.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Small rounded-square yellow "add to bag" button
                    _buildAddButton(context, cart, isDark),
                  ],
                ),
              ],
            ),
          ),

          // Rating Pill INSIDE the card body corner
          Positioned(
            top: 48,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.mustard, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    food.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overflowing Circular Food Photo with ring + soft drop shadow
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onTap,
              child: _buildCircularImage(
                diameter: photoDiameter,
                effectiveTag: effectiveTag,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal card for list & menu views (Fixed height 92, image 72 circle, title max 2 lines)
  Widget _buildHorizontalCard(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveTag = heroTag ?? (food.id.isNotEmpty ? 'food-horiz-${food.id}' : null);

    final hasMultipleVariants = (food.variants != null && food.variants!.length > 1) ||
        (food.sizePrices != null && food.sizePrices!.length > 1);

    final priceText = hasMultipleVariants
        ? 'From Rs. ${food.startingPrice.toStringAsFixed(0)}'
        : 'Rs. ${food.price.toStringAsFixed(0)}';

    return Container(
      height: 92,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.foodCardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppDimens.softShadow(color: AppColors.maroonDeep, opacity: 0.05),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.foodCardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.foodCardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular Food Photo (72px circle with ring and shadow)
                _buildCircularImage(
                  diameter: 72.0,
                  effectiveTag: effectiveTag,
                  isDark: isDark,
                ),

                const SizedBox(width: 12),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Food Name + Spicy badge (max 1-2 lines)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              food.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (food.isSpicy) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: AppColors.tomato,
                              size: 15,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 2),

                      // Description
                      Text(
                        food.description,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Price and Rating aligned on center with flexible price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              priceText,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.star_rounded, color: AppColors.mustard, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            food.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Add to bag button
                _buildAddButton(context, cart, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Circular food photo with ring border, subtle drop shadow and Hero support
  Widget _buildCircularImage({
    required double diameter,
    required String? effectiveTag,
    required bool isDark,
  }) {
    Widget imageContent = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.yellowSoft,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: food.imageUrl != null && food.imageUrl!.isNotEmpty
            ? NetworkImageView(
                imageUrl: food.imageUrl,
                width: diameter,
                height: diameter,
                fit: BoxFit.cover,
                fallbackEmoji: food.imageEmoji,
              )
            : Center(
                child: Text(
                  food.imageEmoji,
                  style: TextStyle(fontSize: diameter * 0.44),
                ),
              ),
      ),
    );

    if (effectiveTag != null && effectiveTag.isNotEmpty) {
      return Hero(
        tag: effectiveTag,
        child: imageContent,
      );
    }
    return imageContent;
  }

  /// Small rounded-square yellow "add to bag" button at bottom-right
  Widget _buildAddButton(BuildContext context, CartProvider cart, bool isDark) {
    final hasCustomization = food.hasVariants || food.hasAddons;
    final qtyInCart = cart.getQuantity(food.id);

    // If item has size variants or addons, show options customization sheet
    if (hasCustomization) {
      return Semantics(
        button: true,
        label: 'Customize ${food.name}',
        child: Tooltip(
          message: 'Customize options',
          child: InkWell(
            onTap: () => ItemCustomizationBottomSheet.show(context, food),
            borderRadius: BorderRadius.circular(AppDimens.radius12),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandYellow,
                borderRadius: BorderRadius.circular(AppDimens.radius12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandYellow.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.onYellow,
                size: 18,
              ),
            ),
          ),
        ),
      );
    }

    // Direct quantity stepper if already in cart
    if (qtyInCart > 0) {
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.brandMaroon,
          borderRadius: BorderRadius.circular(AppDimens.radius12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => cart.decrementQuantity(food.id),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.remove, size: 14, color: AppColors.brandYellow),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '$qtyInCart',
                style: const TextStyle(
                  color: AppColors.brandYellow,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ),
            InkWell(
              onTap: () => cart.addToCart(food),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.add, size: 14, color: AppColors.brandYellow),
              ),
            ),
          ],
        ),
      );
    }

    // Default rounded-square yellow add-to-bag button
    return Semantics(
      button: true,
      label: 'Add ${food.name} to cart',
      child: Tooltip(
        message: 'Add to cart',
        child: InkWell(
          onTap: () {
            if (cart.isDifferentBranch(food.branchId)) {
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
                        cart.addToCart(food);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${food.name} added to cart'),
                            duration: const Duration(milliseconds: 900),
                            backgroundColor: AppColors.brandMaroon,
                          ),
                        );
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

            cart.addToCart(food);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${food.name} added to bag'),
                duration: const Duration(milliseconds: 900),
                backgroundColor: AppColors.brandMaroon,
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppDimens.radius12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandYellow,
              borderRadius: BorderRadius.circular(AppDimens.radius12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandYellow.withValues(alpha: 0.38),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.onYellow,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
