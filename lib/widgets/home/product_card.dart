import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/utils/app_snackbar.dart';
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
  final bool inGrid;

  const ProductCard({
    super.key,
    required this.food,
    required this.onTap,
    this.heroTag,
    this.width = 176.0,
    this.isHorizontalInList = false,
    this.inGrid = false,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.onYellow),
              ),
            ),
          ],
        ),
      );
      return;
    }

    cart.addToCart(widget.food);
    AppSnackbar.showSuccess(context, 'Added to cart',
        action: SnackBarAction(
            label: 'View',
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pushNamed('/cart')));
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final hasOptions = food.hasVariants || (food.variants?.isNotEmpty ?? false);
    final price = 'Rs. ${food.startingPrice.toStringAsFixed(0)}';
    return SizedBox(
      width: widget.inGrid ? null : widget.width,
      child: Card(
        margin: const EdgeInsets.all(AppDimens.space4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AspectRatio(
                aspectRatio: 1.5,
                child: Hero(
                  tag: widget.heroTag ?? 'food-${food.id}',
                  child: NetworkImageView(
                      imageUrl: food.imageUrl, borderRadius: 0),
                )),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(AppDimens.space12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(
                        food.reviewCount > 0
                            ? '★ ${food.rating.toStringAsFixed(1)} (${food.reviewCount})'
                            : 'New',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium),
                    const SizedBox(height: AppDimens.space4),
                    Text(hasOptions ? 'From $price' : price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppDimens.space8),
                    SizedBox(
                      width: double.infinity,
                      height: AppDimens.minTouchTarget,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Semantics(
                          label: 'Add ${food.name} to cart',
                          button: true,
                          child: FilledButton(
                            onPressed: food.isAvailable
                                ? () => _handleAddTap(context, cart)
                                : null,
                            style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero),
                            child: Text(
                                food.isAvailable
                                    ? (hasOptions ? 'Choose' : 'Add')
                                    : 'Unavailable',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ),
                  ]),
            )),
          ]),
        ),
      ),
    );
  }
}
