import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/branch_model.dart';
import '../../models/food_model.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_card.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../providers/restaurant_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  final PageController _promoController = PageController();
  Timer? _promoTimer;
  int _promoIndex = 0;

  @override
  void initState() {
    super.initState();
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final nextIndex = (_promoIndex + 1) % 3;
      _promoController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
      _promoIndex = nextIndex;
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('burger')) return Icons.lunch_dining_rounded;
    if (lower.contains('pizza')) return Icons.local_pizza_rounded;
    if (lower.contains('chicken') || lower.contains('broast') || lower.contains('wing')) {
      return Icons.set_meal_rounded;
    }
    if (lower.contains('shawarma') || lower.contains('roll')) return Icons.fastfood_rounded;
    if (lower.contains('drink') || lower.contains('beverage')) return Icons.local_cafe_rounded;
    if (lower.contains('dessert') || lower.contains('sweet') || lower.contains('ice')) {
      return Icons.cake_rounded;
    }
    if (lower.contains('sushi') || lower.contains('fish')) return Icons.ramen_dining_rounded;
    if (lower.contains('healthy') || lower.contains('salad')) return Icons.eco_rounded;
    if (lower.contains('platter') || lower.contains('combo')) return Icons.auto_awesome_rounded;
    return Icons.restaurant_rounded;
  }

  void _selectBranch(BranchModel branch) {
    final cart = context.read<CartProvider>();

    if (cart.items.isNotEmpty && cart.branchId != null && cart.branchId != branch.id) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Switch Branch?'),
          content: Text(
            'Your cart contains items from another branch. Switching to "${branch.name}" will clear your current cart.',
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                cart.clearCart();
                _applyBranchSelection(branch);
              },
              child: const Text('Clear Cart & Switch'),
            ),
          ],
        ),
      );
    } else {
      _applyBranchSelection(branch);
    }
  }

  void _applyBranchSelection(BranchModel branch) {
    context.read<BranchProvider>().selectBranch(branch);
    context.read<MenuProvider>().watchMenuItems(branchId: branch.id);
    context.read<CouponProvider>().watchCoupons(branchId: branch.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${branch.name} 🥊'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _openBranchSelectionSheet(BuildContext context) {
    final branchProv = context.read<BranchProvider>();
    final activeBranches = branchProv.activeBranches;
    final selectedBranch = branchProv.selectedBranch;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Branch Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Menu, deals & delivery depend on your selected kitchen',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: activeBranches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final branch = activeBranches[index];
                      final isSelected = branch.id == selectedBranch?.id;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          if (!isSelected) {
                            _selectBranch(branch);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? Colors.white12 : Colors.grey.shade200),
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isSelected
                                    ? AppColors.primary
                                    : colorScheme.primary.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.store_mall_directory_rounded,
                                  color: isSelected ? Colors.white : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            branch.name,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'SELECTED',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${branch.city} • ${branch.address}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                color: isSelected ? AppColors.primary : Colors.grey,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBranchCard(BranchModel branch, bool isSelected, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        if (!isSelected) {
          _selectBranch(branch);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: isSelected ? Colors.white : AppColors.primary,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    branch.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${branch.city} • ${branch.address}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Open Now • 25-35m',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSelected ? '✓ Browsing' : 'Switch',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final branchProvider = context.watch<BranchProvider>();
    final couponProvider = context.watch<CouponProvider>();

    final selectedBranch = branchProvider.selectedBranch;

    if (selectedBranch != null && menuProvider.currentBranchId != selectedBranch.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        menuProvider.watchMenuItems(branchId: selectedBranch.id);
        couponProvider.watchCoupons(branchId: selectedBranch.id);
      });
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final firstName = auth.currentUser?.name.split(' ').first ?? 'Fighter';
    final categories = categoryProvider.activeCategories;
    final categoryNames = ['All', ...categories.map((c) => c.name)];

    final catMap = {for (var c in categories) c.id: c.name};
    final allFoods = menuProvider.activeItems.map((item) {
      final catName = catMap[item.categoryId] ?? item.categoryId;
      return FoodModel.fromMenuItem(item, categoryName: catName);
    }).toList();

    final filteredFoods = _selectedCategory == 'All'
        ? allFoods
        : allFoods.where((f) => f.category == _selectedCategory).toList();

    final popularRestaurants = context.watch<RestaurantProvider>().restaurants;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ResponsiveContainer.content(
          child: Builder(
            builder: (context) {
              if (menuProvider.isLoading && allFoods.isEmpty) {
                return const LoadingIndicator(message: 'Loading delicious dishes...');
              }

              if (menuProvider.errorMessage != null && allFoods.isEmpty) {
                return ErrorView(
                  message: menuProvider.errorMessage!,
                  onRetry: () {
                    categoryProvider.fetchCategories();
                    menuProvider.fetchMenuItems();
                  },
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await categoryProvider.fetchCategories();
                  await menuProvider.fetchMenuItems();
                },
                child: CustomScrollView(
                  slivers: [
                    // Top App Bar / Location & Actions
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  AppConstants.logoIconPath,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => _openBranchSelectionSheet(context),
                                borderRadius: BorderRadius.circular(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Ordering from branch',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 16),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.storefront_rounded,
                                          color: AppColors.primary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            selectedBranch?.name ?? 'Main Kitchen',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Admin Portal shortcut button for admin user
                            if (auth.isAdmin)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () => Navigator.of(context).pushNamed('/admin/dashboard'),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D47A1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.admin_panel_settings, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'Admin',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Notification button
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.notifications_outlined,
                                  color: colorScheme.onSurface,
                                  size: 20,
                                ),
                                onPressed: () => Navigator.of(context).pushNamed('/notifications'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Greeting Header (Spec: "Hi, {name} 👋 / What would you like to eat today?")
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, $firstName 👋',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'What would you like to eat today?',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Prominent Search Bar Tap Trigger
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/search'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Search dishes, burgers, pizza...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.tune_rounded,
                                    color: colorScheme.primary,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Promo Banner Carousel (Dynamic from Branch Coupons or Fallback)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
                        child: SizedBox(
                          height: 140,
                          child: couponProvider.activeCoupons.isNotEmpty
                              ? PageView(
                                  controller: _promoController,
                                  onPageChanged: (index) => setState(() => _promoIndex = index),
                                  children: couponProvider.activeCoupons.map((coupon) {
                                    final discount = coupon.type == 'percentage'
                                        ? '${coupon.value.toInt()}% OFF'
                                        : (coupon.type == 'free_delivery' ? 'FREE DELIVERY' : 'Rs. ${coupon.value.toInt()} OFF');
                                    return _buildPromoCard(
                                      'Deal: ${coupon.code}',
                                      '$discount • Min Rs. ${coupon.minimumOrder.toInt()}',
                                      '🎟️',
                                      const [Color(0xFFFF7622), Color(0xFFFF521B)],
                                      context,
                                    );
                                  }).toList(),
                                )
                              : PageView(
                                  controller: _promoController,
                                  onPageChanged: (index) => setState(() => _promoIndex = index),
                                  children: [
                                    _buildPromoCard(
                                      'Fight Club Platter Deal',
                                      'Rs. 849 • Hot & Crispy',
                                      '🍗',
                                      const [Color(0xFFFF7622), Color(0xFFFF521B)],
                                      context,
                                    ),
                                    _buildPromoCard(
                                      'BOGO Shawarma Battle',
                                      'Use Code: FIGHTBOGO',
                                      '🥙',
                                      const [Color(0xFFE56314), Color(0xFFC74300)],
                                      context,
                                    ),
                                    _buildPromoCard(
                                      'Cheese Burst Pizza Combo',
                                      'Special Arena Deal',
                                      '🍕',
                                      const [Color(0xFFFF8E43), Color(0xFFFF641A)],
                                      context,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    // "Our Kitchen Branches" Horizontal Section
                    if (branchProvider.activeBranches.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.store_mall_directory_rounded, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Our Branches',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => _openBranchSelectionSheet(context),
                                child: const Text(
                                  'Switch Location',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 105,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            itemCount: branchProvider.activeBranches.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final branch = branchProvider.activeBranches[index];
                              final isSelected = selectedBranch?.id == branch.id;
                              return _buildBranchCard(branch, isSelected, context);
                            },
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    ],

                    // Horizontal-scroll Category Row with Icon Chips (pulled from Firestore via CategoryProvider)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Categories',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${categoryNames.length - 1} categories',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: categoryNames.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final cat = categoryNames[index];
                            final isSelected = cat == _selectedCategory;
                            final icon = _getCategoryIcon(cat);

                            return GestureDetector(
                              onTap: () => setState(() => _selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.35)
                                          : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      icon,
                                      color: isSelected ? Colors.white : AppColors.primary,
                                      size: 17,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : colorScheme.onSurface,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // "Popular Restaurants" Section Header & Horizontal Row
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Popular Restaurants',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(context).pushNamed('/search'),
                              child: const Text(
                                'See All',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 255,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: popularRestaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = popularRestaurants[index];
                            return RestaurantCard(
                              restaurant: restaurant,
                              isHorizontal: true,
                              onTap: () => Navigator.of(context).pushNamed(
                                '/restaurant-detail',
                                arguments: restaurant,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // "Popular Dishes" Section Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedCategory == 'All' ? 'Popular Dishes' : _selectedCategory,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${filteredFoods.length} items',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Popular Dishes Grid / List
                    if (filteredFoods.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: EmptyStateView(
                            icon: Icons.fastfood_outlined,
                            title: 'No Dishes Found',
                            description: _selectedCategory == 'All'
                                ? 'No food items are currently listed on the menu.'
                                : 'No dishes currently available in "$_selectedCategory".',
                          ),
                        ),
                      )
                    else if (MediaQuery.sizeOf(context).width >= 720)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 440,
                            mainAxisExtent: 130,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final food = filteredFoods[index];
                              return FoodCard(
                                food: food,
                                onTap: () => Navigator.of(context).pushNamed(
                                  '/food-detail',
                                  arguments: food,
                                ),
                              );
                            },
                            childCount: filteredFoods.length,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final food = filteredFoods[index];
                              return FoodCard(
                                food: food,
                                onTap: () => Navigator.of(context).pushNamed(
                                  '/food-detail',
                                  arguments: food,
                                ),
                              );
                            },
                            childCount: filteredFoods.length,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCard(
    String title,
    String subtitle,
    String emoji,
    List<Color> gradientColors,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'HOT DEAL 🥊',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 48)),
        ],
      ),
    );
  }
}
