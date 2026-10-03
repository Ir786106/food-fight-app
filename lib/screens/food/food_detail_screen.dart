import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../models/food_model.dart';
import '../../models/menu_item_model.dart';
import '../../models/review_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/common/network_image_view.dart';
import '../../widgets/home/product_card.dart';

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
  String? _watchedFoodId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    String? foodId;
    if (args is FoodModel) {
      foodId = args.id;
    } else if (args is MenuItemModel) {
      foodId = args.id;
    } else if (args is String) {
      foodId = args;
    }
    if (foodId != null && foodId != _watchedFoodId) {
      _watchedFoodId = foodId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ReviewProvider>().watchItemReviews(foodId!);
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _openImagePreview(BuildContext context, FoodModel food) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.8,
                maxScale: 3.5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                      ? NetworkImageView(
                          imageUrl: food.imageUrl,
                          width: 320,
                          height: 320,
                          fit: BoxFit.cover,
                          fallbackEmoji: food.imageEmoji,
                        )
                      : Container(
                          width: 280,
                          height: 280,
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: Text(food.imageEmoji, style: const TextStyle(fontSize: 120)),
                        ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  String _getShortVariantLabel(String label) {
    final lower = label.trim().toLowerCase();
    if (lower == 'small' || lower == 's') return 'S';
    if (lower == 'medium' || lower == 'm') return 'M';
    if (lower == 'large' || lower == 'l') return 'L';
    if (lower == 'extra large' || lower == 'xl') return 'XL';
    if (lower == 'regular' || lower == 'reg') return 'Reg';
    if (lower == 'half') return 'Half';
    if (lower == 'full') return 'Full';
    if (label.length <= 4) return label;
    return label.substring(0, 3);
  }

  void _shareDish(FoodModel food) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${food.name}" with friends!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radius12)),
      ),
    );
  }

  void _reportDish(FoodModel food) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radius16)),
        title: const Text('Report Dish or Menu Issue'),
        content: Text('Let us know if anything is wrong with "${food.name}" (incorrect price, ingredients, or allergens).'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you! Feedback submitted to restaurant management.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _handleAddToCart(FoodModel food, CartProvider cart, double totalPrice) {
    HapticFeedback.lightImpact();

    if (cart.isDifferentBranch(food.branchId)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radius16)),
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
                  note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                  selectedVariant: _selectedVariant,
                  selectedSize: _selectedVariant?.label,
                  selectedAddons: _selectedAddons.toList(),
                );
                Navigator.of(context).pop();
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
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      selectedVariant: _selectedVariant,
      selectedSize: _selectedVariant?.label,
      selectedAddons: _selectedAddons.toList(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    FoodModel? food;
    if (args is FoodModel) {
      food = args;
    } else if (args is MenuItemModel) {
      food = FoodModel.fromMenuItem(args);
    } else if (args is String) {
      final menu = context.watch<MenuProvider>();
      final item = menu.menuItems.where((i) => i.id == args).firstOrNull;
      if (item != null) {
        food = FoodModel.fromMenuItem(item);
      }
    }

    if (food == null) {
      final theme = Theme.of(context);
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Dish Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fastfood_outlined, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text(
                  'Dish Not Found',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The requested dish could not be loaded or is unavailable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandYellow,
                    foregroundColor: AppColors.brandMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final FoodModel foodItem = food;
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isFav = cart.isFavorite(food.id);

    if (!_initialized) {
      if (food.hasVariants && food.variants!.isNotEmpty) {
        _selectedVariant = food.variants!.first;
      }
      _initialized = true;
    }

    final double basePrice = _selectedVariant != null ? _selectedVariant!.finalPrice : food.price;
    final double addonsTotal = _selectedAddons.fold(0.0, (sum, a) => sum + a.price);
    final double unitPrice = basePrice + addonsTotal;
    final double totalPrice = unitPrice * _quantity;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: colorScheme.onSurface,
                  size: 17,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              food.category.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              food.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Favorite Heart Button with bounce animation and tomato color (Ref A)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(isFav),
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? AppColors.tomato : colorScheme.onSurface,
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        cart.toggleFavorite(foodItem);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          // Three Dots Overflow Menu (Ref C)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radius14)),
                onSelected: (val) {
                  if (val == 'share') _shareDish(foodItem);
                  if (val == 'report') _reportDish(foodItem);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Share Dish'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, size: 18, color: AppColors.error),
                        SizedBox(width: 10),
                        Text('Report Issue', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // Large Circular Hero Product Image on soft cream plate (Ref A & Audit 11)
            Center(
              child: GestureDetector(
                onTap: () => _openImagePreview(context, foodItem),
                child: Hero(
                  tag: 'food-${food.id}',
                  child: Container(
                    width: 236,
                    height: 236,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.yellowSoft,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                          blurRadius: 28,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                          ? NetworkImageView(
                              imageUrl: food.imageUrl,
                              width: 220,
                              height: 220,
                              fit: BoxFit.cover,
                              fallbackEmoji: food.imageEmoji,
                            )
                          : Center(
                              child: Text(
                                food.imageEmoji,
                                style: const TextStyle(fontSize: 100),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Under Image portion description and live price (Ref A)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      _selectedVariant != null
                          ? '${_selectedVariant!.label} size • ${_selectedVariant!.description ?? "Freshly made standard portion"}'
                          : (food.description.isNotEmpty ? food.description : 'Standard Portion'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live price: Rs. ${unitPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandMaroon,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Food Details Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Live Unit Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Rs. ${unitPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating + Time + Spicy Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandYellow.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(AppDimens.radius8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.onYellowDark),
                            const SizedBox(width: 4),
                            Text(
                              '${food.rating}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onYellowDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppDimens.radius8),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                          ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppDimens.radius8),
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

                  // S / M / L Rounded-Square Selector (Ref A)
                  if (food.hasVariants) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Size / Portion',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.errorSoft,
                                borderRadius: BorderRadius.circular(AppDimens.radius8),
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
                        if (_selectedVariant != null)
                          Text(
                            _selectedVariant!.label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: food.variants!.map((v) {
                        final isSelected = _selectedVariant?.label == v.label;
                        final shortCode = _getShortVariantLabel(v.label);

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedVariant = v);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandYellow
                                  : (isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted),
                              borderRadius: BorderRadius.circular(AppDimens.radius16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.brandYellow
                                    : (isDark ? AppColors.darkBorder : AppColors.border),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.brandYellow.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  shortCode,
                                  style: TextStyle(
                                    fontSize: shortCode.length <= 2 ? 15 : 12,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    color: isSelected ? AppColors.brandMaroon : AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Rs.${v.finalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    color: isSelected
                                        ? AppColors.brandMaroon
                                        : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Quantity Stepper (− 1 +) with Yellow Plus (Ref A)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppDimens.radius16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _quantity > 1
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _quantity--);
                                    }
                                  : null,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(AppDimens.radius12),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: _quantity > 1
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
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
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _quantity++);
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.brandYellow,
                                  borderRadius: BorderRadius.circular(AppDimens.radius12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandYellow.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: AppColors.onYellowDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Segmented Tabs (Overview / Options / Reviews)
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radius14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppDimens.radius12),
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

                  // Tab Contents
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
                    // Nutritional Highlights
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
                        color: isDark ? AppColors.darkSurfaceElevated : colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radius14),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Freshly prepared in 15–20 minutes • 100% Halal certified',
                              style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_tabController.index == 1) ...[
                    // Tab 1: Options & Add-ons
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
                              color: colorScheme.surfaceContainerHighest,
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
                            HapticFeedback.selectionClick();
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
                                  : (isDark ? AppColors.darkSurfaceElevated : colorScheme.surface),
                              borderRadius: BorderRadius.circular(AppDimens.radius16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkBorder : AppColors.border),
                                width: isSelected ? 1.8 : 1,
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
                                  child: isSelected ? const Icon(Icons.check, size: 16, color: AppColors.onYellow) : null,
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
                                    color: isDark ? AppColors.brandYellow : AppColors.amberDark,
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
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: 'e.g. Extra sauce, no spicy seasoning...',
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceElevated : colorScheme.surface,
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 13.5,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radius14),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Tab 2: Reviews
                    _buildDishReviews(food, colorScheme, isDark),
                  ],

                  // Related Items Strip: "You may also like" (Ref A)
                  Builder(
                    builder: (context) {
                      MenuProvider? menuProv;
                      try {
                        menuProv = Provider.of<MenuProvider>(context);
                      } catch (_) {
                        menuProv = null;
                      }
                      if (menuProv == null) return const SizedBox.shrink();

                      final relatedItems = menuProv.activeItems
                          .where((item) => item.id != foodItem.id)
                          .map((item) => FoodModel.fromMenuItem(item, categoryName: item.categoryId))
                          .take(5)
                          .toList();

                      if (relatedItems.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            'You may also like',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 230,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: relatedItems.length,
                              itemBuilder: (context, idx) {
                                final item = relatedItems[idx];
                                return ProductCard(
                                  food: item,
                                  heroTag: 'rel-${item.id}',
                                  width: 160,
                                  onTap: () => Navigator.of(context).pushReplacementNamed(
                                    '/food-detail',
                                    arguments: item,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 110), // clearance for bottom action bar
                ],
              ),
            ),
          ],
        ),
      ),

      // Sticky Bottom MaroonDeep Pill "Add to cart · Rs X" CTA with yellow bag square (Ref A)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleAddToCart(foodItem, cart, totalPrice),
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.maroonDeep, // MaroonDeep #4A1517
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.maroonDeep.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Yellow bag icon square
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.brandYellow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: AppColors.brandMaroon,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Add to cart · Rs. ${totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.brandYellow,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionChip(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppDimens.radius12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDishReviews(FoodModel food, ColorScheme colorScheme, bool isDark) {
    final reviewProv = context.watch<ReviewProvider>();
    final reviews = reviewProv.itemReviews;
    final avgRating = reviews.isEmpty ? food.rating : reviewProv.averageRating;
    final totalCount = reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : colorScheme.surface,
            borderRadius: BorderRadius.circular(AppDimens.radius16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: AppColors.accent,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalCount == 0
                          ? 'No reviews yet • Be the first to rate after ordering!'
                          : 'Based on $totalCount verified customer review${totalCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDimens.radius16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined, size: 40, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 10),
                Text(
                  'No Reviews Written Yet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reviews appear here once customers order and review this dish.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          ...reviews.map((rev) => _buildRealReviewTile(rev, colorScheme, isDark)),
      ],
    );
  }

  Widget _buildRealReviewTile(ReviewModel rev, ColorScheme colorScheme, bool isDark) {
    final dateStr = '${rev.createdAt.day}/${rev.createdAt.month}/${rev.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.brandYellow,
                    child: Text(
                      (rev.userName != null && rev.userName!.isNotEmpty) ? rev.userName![0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandMaroon, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (rev.userName != null && rev.userName!.isNotEmpty) ? rev.userName! : 'Verified Foodie',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: colorScheme.onSurface),
                  ),
                ],
              ),
              Text(
                dateStr,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < rev.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.mustard,
                  size: 15,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                rev.rating.toStringAsFixed(1),
                style: const TextStyle(color: AppColors.mustard, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          if (rev.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(rev.comment, style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant)),
          ],
          if (rev.adminReply != null && rev.adminReply!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brandYellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply_rounded, size: 16, color: AppColors.brandMaroon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Restaurant Response',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: AppColors.brandMaroon),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rev.adminReply!,
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
