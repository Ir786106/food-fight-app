import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/core/constants/app_colors.dart';
import 'package:food_fight/models/food_model.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/providers/cart_provider.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:food_fight/widgets/common/network_image_view.dart';
import 'package:food_fight/widgets/custom_button.dart';

/// Modal bottom sheet allowing customer to customize item size/variant and add-ons
class ItemCustomizationBottomSheet extends StatefulWidget {
  final FoodModel food;

  const ItemCustomizationBottomSheet({super.key, required this.food});

  /// Helper to show this bottom sheet conveniently
  static Future<void> show(BuildContext context, FoodModel food) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ItemCustomizationBottomSheet(food: food),
    );
  }

  @override
  State<ItemCustomizationBottomSheet> createState() =>
      _ItemCustomizationBottomSheetState();
}

class _ItemCustomizationBottomSheetState
    extends State<ItemCustomizationBottomSheet> {
  late MenuVariant? _selectedVariant;
  final Set<MenuAddon> _selectedAddons = {};
  int _quantity = 1;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default to first variant if item has variants
    if (widget.food.hasVariants) {
      _selectedVariant = widget.food.variants!.first;
    } else {
      _selectedVariant = null;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _currentUnitPrice {
    final basePrice = _selectedVariant != null
        ? _selectedVariant!.finalPrice
        : widget.food.price;
    final addonsTotal =
        _selectedAddons.fold(0.0, (sum, addon) => sum + addon.price);
    return basePrice + addonsTotal;
  }

  double get _currentTotalPrice => _currentUnitPrice * _quantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final food = widget.food;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable Options Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Header Card
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                            ? NetworkImageView(
                                imageUrl: food.imageUrl,
                                width: 76,
                                height: 76,
                                borderRadius: 16,
                                fallbackEmoji: food.imageEmoji,
                              )
                            : Text(food.imageEmoji,
                                style: const TextStyle(fontSize: 36)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    food.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                if (food.isSpicy)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Text('🌶️', style: TextStyle(fontSize: 13)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              food.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              food.hasVariants
                                  ? 'From Rs. ${food.startingPrice.toStringAsFixed(0)}'
                                  : 'Rs. ${food.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 18),

                  // Section 1: Choose Size / Variant (Required if item has variants)
                  if (food.hasVariants) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Choose Size / Portion',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppColors.errorSoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Text(
                            'Required',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...food.variants!.map((variant) {
                      final isSelected = _selectedVariant?.label == variant.label;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedVariant = variant;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary.withValues(alpha: 0.08)
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant.withValues(alpha: 0.6),
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppColors.brandYellow : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? AppColors.brandYellow : (isDark ? AppColors.darkBorder : AppColors.border),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Center(
                                        child: Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: AppColors.onYellow,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      variant.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    if (variant.description != null &&
                                        variant.description!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          variant.description!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rs. ${variant.finalPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                    ),
                                  ),
                                  if (variant.discount > 0)
                                    Text(
                                      'Rs. ${variant.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: 11.5,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // Section 2: Optional Extras & Add-ons
                  if (food.hasAddons) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Extras & Add-ons',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.border,
                            ),
                          ),
                          child: Text(
                            'Optional',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...food.addons!.map((addon) {
                      final isSelected = _selectedAddons.contains(addon);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedAddons.remove(addon);
                            } else {
                              _selectedAddons.add(addon);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary.withValues(alpha: 0.06)
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant.withValues(alpha: 0.6),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.brandYellow : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? AppColors.brandYellow : (isDark ? AppColors.darkBorder : AppColors.border),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 16, color: AppColors.onYellow)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  addon.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                '+ Rs. ${addon.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: isDark ? AppColors.brandYellow : AppColors.amberDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // Section 3: Special Instructions Note
                  Text(
                    'Special Instructions',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Extra napkins, no spicy sauce...',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                // Quantity Stepper (Ref A: minus, count, yellow plus)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: _quantity > 1
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_quantity',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _quantity++),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brandYellow.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: AppColors.onYellow,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Add to Bucket Dark Pill CTA (Ref A/C & Component Set)
                Expanded(
                  child: CustomButton.darkCta(
                    text: 'Add to bucket',
                    priceBadge: 'Rs. ${_currentTotalPrice.toStringAsFixed(0)}',
                    onPressed: () {
                      final cart = context.read<CartProvider>();
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
                                  backgroundColor: AppColors.brandYellow,
                                  foregroundColor: AppColors.onYellow,
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  cart.clearCart();
                                  cart.addToCart(
                                    food,
                                    quantity: _quantity,
                                    note: _noteCtrl.text.trim().isEmpty
                                        ? null
                                        : _noteCtrl.text.trim(),
                                    selectedVariant: _selectedVariant,
                                    selectedSize: _selectedVariant?.label,
                                    selectedAddons: _selectedAddons.toList(),
                                  );
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${food.name} added to new cart!'),
                                      backgroundColor: AppColors.brandMaroon,
                                      duration: const Duration(milliseconds: 1000),
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

                      cart.addToCart(
                        food,
                        quantity: _quantity,
                        note: _noteCtrl.text.trim().isEmpty
                            ? null
                            : _noteCtrl.text.trim(),
                        selectedVariant: _selectedVariant,
                        selectedSize: _selectedVariant?.label,
                        selectedAddons: _selectedAddons.toList(),
                      );

                      Navigator.of(context).pop();

                      final variantSuffix = _selectedVariant != null
                          ? ' (${_selectedVariant!.label})'
                          : '';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${food.name}$variantSuffix added to bucket!'),
                          backgroundColor: AppColors.brandMaroon,
                          duration: const Duration(milliseconds: 1000),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
