import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_model.dart';
import '../../models/menu_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/common/network_image_view.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({super.key});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  int _quantity = 1;
  final _noteController = TextEditingController();
  MenuVariant? _selectedVariant;
  final Set<MenuAddon> _selectedAddons = {};
  bool _initialized = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final food = ModalRoute.of(context)!.settings.arguments as FoodModel;
    final cart = context.watch<CartProvider>();

    if (!_initialized) {
      if (food.hasVariants) {
        _selectedVariant = food.variants!.first;
      }
      _initialized = true;
    }

    final double basePrice = _selectedVariant != null
        ? _selectedVariant!.finalPrice
        : food.price;
    final double addonsTotal =
        _selectedAddons.fold(0.0, (sum, a) => sum + a.price);
    final double effectivePrice = basePrice + addonsTotal;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.textPrimary, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'food-${food.id}',
                child: Container(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  alignment: Alignment.center,
                  child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                      ? NetworkImageView(
                          imageUrl: food.imageUrl,
                          width: double.infinity,
                          height: 260,
                          fit: BoxFit.cover,
                          fallbackEmoji: food.imageEmoji,
                        )
                      : Text(food.imageEmoji,
                          style: const TextStyle(fontSize: 120)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        food.hasVariants
                            ? 'From Rs. ${food.startingPrice.toStringAsFixed(0)}'
                            : 'Rs. ${effectivePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text('${food.rating}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text('${food.prepTimeMinutes} min',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      if (food.isSpicy)
                        const Text('🌶️ Spicy', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Description',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(
                    food.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5),
                  ),
                  const SizedBox(height: 18),

                  // Section: Variants / Sizes
                  if (food.hasVariants) ...[
                    Row(
                      children: [
                        const Text('Choose Size / Portion',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Required',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...food.variants!.map((v) {
                      final isSelected = _selectedVariant?.label == v.label;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedVariant = v),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v.label,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                    ),
                                    if (v.description != null &&
                                        v.description!.isNotEmpty)
                                      Text(
                                        v.description!,
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.grey.shade600),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rs. ${v.finalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                  ],

                  // Section: Extras & Add-ons
                  if (food.hasAddons) ...[
                    Row(
                      children: [
                        const Text('Extras & Add-ons',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Optional',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
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
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.06)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  addon.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5),
                                ),
                              ),
                              Text(
                                '+ Rs. ${addon.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                  ],

                  const Text('Special Instructions',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. No onions, extra sauce...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Quantity',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const Spacer(),
                      _quantityButton(Icons.remove, () {
                        if (_quantity > 1) setState(() => _quantity--);
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text('$_quantity',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      _quantityButton(Icons.add, () {
                        setState(() => _quantity++);
                      }),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CustomButton(
            text:
                'Add to Cart • Rs. ${(effectivePrice * _quantity).toStringAsFixed(0)}',
            onPressed: () {
              cart.addToCart(
                food,
                quantity: _quantity,
                note: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
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
                  content: Text('${food.name}$variantSuffix added to cart!'),
                  backgroundColor: AppColors.secondary,
                  duration: const Duration(milliseconds: 900),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
