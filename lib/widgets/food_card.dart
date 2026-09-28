import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_model.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'common/network_image_view.dart';
import 'menu/item_customization_bottom_sheet.dart';

class FoodCard extends StatelessWidget {
  final FoodModel food;
  final VoidCallback onTap;
  final String? heroTag;

  const FoodCard({
    super.key,
    required this.food,
    required this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget imageBox = Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: food.imageUrl != null && food.imageUrl!.isNotEmpty
          ? NetworkImageView(
              imageUrl: food.imageUrl,
              width: 68,
              height: 68,
              borderRadius: 14,
              fallbackEmoji: food.imageEmoji,
            )
          : Text(food.imageEmoji, style: const TextStyle(fontSize: 32)),
    );

    final effectiveTag = heroTag ?? (food.id.isNotEmpty ? 'food-${food.id}' : null);
    if (effectiveTag != null && effectiveTag.isNotEmpty) {
      imageBox = Hero(
        tag: effectiveTag,
        child: imageBox,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.48)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                imageBox,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              food.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (food.isSpicy)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.local_fire_department_rounded,
                                color: colorScheme.primary,
                                size: 13,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        food.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          Text(
                            food.hasVariants
                                ? 'From Rs. ${food.startingPrice.toStringAsFixed(0)}'
                                : 'Rs. ${food.price.toStringAsFixed(0)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: AppColors.accent, size: 13),
                              const SizedBox(width: 2),
                              Text(
                                '${food.rating}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    final hasCustomization = food.hasVariants || food.hasAddons;
                    final qtyInCart = cart.getQuantity(food.id);

                    if (hasCustomization) {
                      return InkWell(
                        onTap: () => ItemCustomizationBottomSheet.show(context, food),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'OPTIONS',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(Icons.add, color: colorScheme.primary, size: 13),
                            ],
                          ),
                        ),
                      );
                    }

                    if (qtyInCart > 0) {
                      return Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => cart.decrementQuantity(food.id),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Icon(Icons.remove, size: 14, color: Colors.white),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '$qtyInCart',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => cart.addToCart(food),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Icon(Icons.add, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return InkWell(
                      onTap: () {
                        if (cart.isDifferentBranch(food.branchId)) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    cart.clearCart();
                                    cart.addToCart(food);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${food.name} added to new cart 🥊'),
                                        duration: const Duration(milliseconds: 900),
                                        backgroundColor: colorScheme.secondary,
                                      ),
                                    );
                                  },
                                  child: const Text('Start New Cart'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        cart.addToCart(food);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${food.name} added to cart 🥊'),
                            duration: const Duration(milliseconds: 900),
                            backgroundColor: colorScheme.secondary,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.add, color: colorScheme.onPrimary, size: 20),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
