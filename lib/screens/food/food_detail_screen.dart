import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_model.dart';
import '../../models/menu_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/network_image_view.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({super.key});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> with SingleTickerProviderStateMixin {
  int _quantity = 1;
  final _noteController = TextEditingController();
  MenuVariant? _selectedVariant;
  final Set<MenuAddon> _selectedAddons = {};
  bool _initialized = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final food = ModalRoute.of(context)!.settings.arguments as FoodModel;
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isFav = cart.isFavorite(food.id);

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
    final double unitPrice = basePrice + addonsTotal;
    final double totalPrice = unitPrice * _quantity;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Hero AppBar with favorite & share overlays
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            backgroundColor: colorScheme.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: colorScheme.onSurface,
                    size: 18,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              // Share button
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.share_outlined, color: colorScheme.onSurface, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sharing "${food.name}" with friends! 🥊'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    );
                  },
                ),
              ),
              // Favorite button
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? AppColors.primary : colorScheme.onSurface,
                    size: 20,
                  ),
                  onPressed: () {
                    cart.toggleFavorite(food);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFav
                              ? 'Removed from Favorites'
                              : 'Saved "${food.name}" to Favorites ❤️',
                        ),
                        duration: const Duration(milliseconds: 900),
                        backgroundColor: isFav ? colorScheme.surface : AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'food-${food.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                          ? NetworkImageView(
                              imageUrl: food.imageUrl,
                              width: double.infinity,
                              height: 290,
                              fit: BoxFit.cover,
                              fallbackEmoji: food.imageEmoji,
                            )
                          : Text(food.imageEmoji, style: const TextStyle(fontSize: 110)),
                    ),
                    // Gradient vignette
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Food Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Rs. ${unitPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rating + Delivery Time + Spicy Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              '${food.rating}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded, size: 15, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 5),
                            Text(
                              '${food.prepTimeMinutes} mins',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (food.isSpicy)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🌶️', style: TextStyle(fontSize: 12)),
                              SizedBox(width: 4),
                              Text(
                                'Spicy',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sectioned Menu/Reviews/Info Tabs (Spec benchmark)
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Options'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tab 0 / Tab 1 / Tab 2 Content dynamically switched
                  if (_tabController.index == 0) ...[
                    // Tab 0: Overview
                    Text(
                      'About this dish',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      food.description,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Nutritional highlights
                    Row(
                      children: [
                        _buildNutritionChip('Calories', '580 kcal', Icons.local_fire_department_rounded, AppColors.primary),
                        const SizedBox(width: 8),
                        _buildNutritionChip('Protein', '28g', Icons.fitness_center_rounded, AppColors.success),
                        const SizedBox(width: 8),
                        _buildNutritionChip('Carbs', '42g', Icons.grain_rounded, AppColors.warning),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Freshly cooked in 15–20 minutes • 100% Halal certified',
                              style: TextStyle(fontSize: 12.5, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (food.hasVariants || food.hasAddons) ...[
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () => _tabController.animateTo(1),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Customize Portions & Add-ons →', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ] else if (_tabController.index == 1) ...[
                    // Tab 1: Options
                    if (food.hasVariants) ...[
                      Row(
                        children: [
                          Text(
                            'Choose Size / Portion',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Required',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...food.variants!.map((v) {
                        final isSelected = _selectedVariant?.label == v.label;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedVariant = v),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: isSelected ? AppColors.primary : colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    v.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Rs. ${v.finalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    if (food.hasAddons) ...[
                      Row(
                        children: [
                          Text(
                            'Additional Options',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Optional Add-ons',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  color: isSelected ? AppColors.primary : colorScheme.onSurfaceVariant,
                                  size: 22,
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      'Special Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Extra spicy, no mayo, dressing on the side...',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Tab 2: Reviews
                    _buildDishReviews(food, colorScheme),
                  ],
                  const SizedBox(height: 20),

                  // Quantity Stepper Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _quantityButton(Icons.remove, () {
                              if (_quantity > 1) setState(() => _quantity--);
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '$_quantity',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            _quantityButton(Icons.add, () {
                              setState(() => _quantity++);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 110), // clearance for sticky bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky Bottom Action Bar (Spec benchmark: Running subtotal + "Add to Cart" button)
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Running Subtotal
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rs. ${totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),

              // Add to Cart Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
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
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                cart.clearCart();
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${food.name} added to new cart! 🥊'),
                                    backgroundColor: colorScheme.secondary,
                                    duration: const Duration(milliseconds: 900),
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
                        content: Text('${food.name}$variantSuffix added to cart! 🥊'),
                        backgroundColor: colorScheme.secondary,
                        duration: const Duration(milliseconds: 900),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                  label: const Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: colorScheme.onSurface),
      ),
    );
  }

  Widget _buildNutritionChip(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildDishReviews(FoodModel food, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Text(
                '${food.rating}',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Based on 36 customer ratings', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _dishReviewTile('Farhan Ali', '5.0', 'Super crispy and well seasoned! Definitely ordering again.', '2 days ago'),
        const SizedBox(height: 8),
        _dishReviewTile('Sara Malik', '4.5', 'Fresh ingredients and arrived hot. Love the sauce balance.', '5 days ago'),
      ],
    );
  }

  Widget _dishReviewTile(String author, String rating, String comment, String date) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1D26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white)),
              Text(date, style: const TextStyle(fontSize: 11, color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
              const SizedBox(width: 4),
              Text(rating, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

