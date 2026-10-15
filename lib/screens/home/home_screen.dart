import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/deal_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/food_model.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/home/category_rail.dart';
import '../../widgets/home/product_card.dart';
import '../../widgets/home/home_promo_carousel.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/offline_banner.dart';
import '../../widgets/common/out_of_delivery_area_banner.dart';
import '../../widgets/skeleton/food_card_skeleton.dart';
import '../../routes/role_router.dart';
import '../../core/responsive/responsive.dart';

class HomeScreen extends StatefulWidget {
  final ScrollController? parentScrollController;

  const HomeScreen({super.key, this.parentScrollController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedRailCategory = 'All';
  String _selectedTextTab = 'All';
  final PageController _promoController = PageController();
  final ScrollController _contentScrollController = ScrollController();
  Timer? _promoTimer;
  int _promoIndex = 0;

  bool _filterOnlyVeg = false;
  bool _filterOnlySpicy = false;
  String _sortBy = 'popular';

  final List<String> _textTabs = const ['Popular', 'Recommended', 'New', 'All'];

  final Map<String, String> _categoryEmojiMap = {
    'all': '🍽️',
    'burger': '🍔',
    'burgers': '🍔',
    'pizza': '🍕',
    'pizzas': '🍕',
    'chicken': '🍗',
    'broast': '🍗',
    'wings': '🍗',
    'fries': '🍟',
    'sides': '🍟',
    'drink': '🥤',
    'drinks': '🥤',
    'beverages': '🥤',
    'dessert': '🍰',
    'desserts': '🍰',
    'deals': '🏷️',
    'combos': '🥊',
    'fast food': '🍔',
  };

  String _getCategoryEmoji(String categoryName) {
    final lower = categoryName.toLowerCase().trim();
    for (final entry in _categoryEmojiMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return '🍽️';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BranchProvider>().autoResolveNearestBranch(context: context);
      }
    });

    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        if (!_promoController.hasClients) return;
        final nextIndex = (_promoIndex + 1) % 3;
        _promoController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
        _promoIndex = nextIndex;
      });
    }
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String categoryName) {
    setState(() {
      _selectedRailCategory = categoryName;
    });
    if (_contentScrollController.hasClients) {
      _contentScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text('Filter & Sort Dishes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Vegetarian only (🌱)'),
                value: _filterOnlyVeg,
                activeTrackColor: AppColors.lettuce,
                onChanged: (val) {
                  setSheetState(() => _filterOnlyVeg = val);
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Spicy only (🌶️)'),
                value: _filterOnlySpicy,
                activeTrackColor: AppColors.tomato,
                onChanged: (val) {
                  setSheetState(() => _filterOnlySpicy = val);
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              const Text('Sort by', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Popular'),
                    selected: _sortBy == 'popular',
                    onSelected: (s) {
                      setSheetState(() => _sortBy = 'popular');
                      setState(() {});
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Rating'),
                    selected: _sortBy == 'rating',
                    onSelected: (s) {
                      setSheetState(() => _sortBy = 'rating');
                      setState(() {});
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Price: Low to High'),
                    selected: _sortBy == 'price_low',
                    onSelected: (s) {
                      setSheetState(() => _sortBy = 'price_low');
                      setState(() {});
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Price: High to Low'),
                    selected: _sortBy == 'price_high',
                    onSelected: (s) {
                      setSheetState(() => _sortBy = 'price_high');
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: AppColors.brandMaroon,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  void _openMenuDrawerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quick Navigation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.restaurant_menu_rounded, color: AppColors.brandYellow),
                title: const Text('Full Menu'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/menu');
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_rounded, color: AppColors.brandYellow),
                title: const Text('Order History'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/orders');
                },
              ),
              ListTile(
                leading: const Icon(Icons.stars_rounded, color: AppColors.brandYellow),
                title: const Text('Loyalty & Rewards'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/loyalty');
                },
              ),
              ListTile(
                leading: const Icon(Icons.headset_mic_rounded, color: AppColors.brandYellow),
                title: const Text('Customer Support Chat'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/chat');
                },
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    final categoryProvider = context.watch<CategoryProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final branchProvider = context.watch<BranchProvider>();
    final dealProvider = context.watch<DealProvider>();
    final notifProvider = context.watch<NotificationProvider?>();
    final auth = context.watch<AuthProvider>();

    final selectedBranch = branchProvider.selectedBranch;

    if (selectedBranch != null && menuProvider.currentBranchId != selectedBranch.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        menuProvider.watchMenuItems(branchId: selectedBranch.id);
        dealProvider.watchDeals(branchId: selectedBranch.id, activeOnly: true);
      });
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = categoryProvider.activeCategories;
    final catMap = {for (var c in categories) c.id: c.name};

    final seenIds = <String>{};
    final allFoods = <FoodModel>[];
    for (final item in menuProvider.activeItems) {
      if (seenIds.add(item.id)) {
        final catName = catMap[item.categoryId] ?? item.categoryId;
        allFoods.add(FoodModel.fromMenuItem(item, categoryName: catName));
      }
    }

    // Filter by category
    List<FoodModel> filteredByRail = _selectedRailCategory == 'All'
        ? allFoods
        : allFoods.where((f) => f.category.toLowerCase() == _selectedRailCategory.toLowerCase()).toList();

    // Filter by text tab
    if (_selectedTextTab == 'Popular') {
      filteredByRail = filteredByRail.where((f) => f.rating >= 4.0).toList().isEmpty
          ? filteredByRail
          : (List<FoodModel>.from(filteredByRail)..sort((a, b) => b.rating.compareTo(a.rating)));
    } else if (_selectedTextTab == 'Recommended') {
      filteredByRail = filteredByRail.reversed.toList();
    } else if (_selectedTextTab == 'New') {
      filteredByRail = filteredByRail.take(10).toList();
    }

    // Filter by options
    if (_filterOnlyVeg) {
      filteredByRail = filteredByRail.where((f) => f.isVeg).toList();
    }
    if (_filterOnlySpicy) {
      filteredByRail = filteredByRail.where((f) => f.isSpicy).toList();
    }

    // Sort
    if (_sortBy == 'price_low') {
      filteredByRail.sort((a, b) => a.startingPrice.compareTo(b.startingPrice));
    } else if (_sortBy == 'price_high') {
      filteredByRail.sort((a, b) => b.startingPrice.compareTo(a.startingPrice));
    } else if (_sortBy == 'rating') {
      filteredByRail.sort((a, b) => b.rating.compareTo(a.rating));
    }

    final popularFoods = allFoods.where((f) => f.rating >= 4.4).toList();
    final effectivePopularFoods = popularFoods.isNotEmpty ? popularFoods : allFoods.take(6).toList();
    final recommendedFoods = allFoods.reversed.take(8).toList();

    final hasUnreadNotifications = (notifProvider?.unreadCount ?? 0) > 0;
    final userName = auth.currentUser?.name;
    final greetingText = (userName != null && userName.isNotEmpty)
        ? 'Hello, ${userName.split(' ').first}! 🥊'
        : 'Food Fight Kitchen 🥊';

    final categoriesWithAll = ['All', ...categories.map((c) => c.name)];

    Widget mainContent = Builder(
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
          color: AppColors.brandYellow,
          backgroundColor: AppColors.brandMaroon,
          onRefresh: () async {
            await categoryProvider.fetchCategories();
            await menuProvider.fetchMenuItems();
          },
          child: CustomScrollView(
            controller: _contentScrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // 0. Offline Banner
              const SliverToBoxAdapter(
                child: OfflineBanner(),
              ),

              // 0.1 Admin/Super Admin Storefront Preview Banner
              if (auth.isSuperAdmin || auth.isAdmin)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: auth.isSuperAdmin
                            ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                            : [AppColors.brandMaroon, AppColors.maroonDeep],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          auth.isSuperAdmin ? Icons.shield_rounded : Icons.storefront_rounded,
                          color: AppColors.brandYellow,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            auth.isSuperAdmin
                                ? 'Super Admin Preview Mode'
                                : 'Branch Admin Preview Mode',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              RoleRouter.navigateHome(context, auth.currentUser);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brandYellow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_back_rounded, size: 14, color: AppColors.brandMaroon),
                                const SizedBox(width: 4),
                                Text(
                                  auth.isSuperAdmin ? 'Back to Super Admin' : 'Back to Admin',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brandMaroon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 1. Mobile & Desktop Header Top Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greetingText,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Freshly cooked fast food',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Loyalty tokens chip
                      InkWell(
                        onTap: () => Navigator.of(context).pushNamed('/loyalty'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🥊', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Consumer<LoyaltyProvider>(
                                builder: (_, lp, __) => Text(
                                  '${lp.tokensBalance}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bell Notifications
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, size: 24),
                            color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                            tooltip: 'Notifications',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
                          ),
                          if (hasUnreadNotifications)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.tomato,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Read-only Auto Delivery Location Pill
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.brandYellow,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            branchProvider.getDeliveryLabel(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Out of Delivery Area Banner (If GPS out of bounds)
              if (branchProvider.isOutOfDeliveryArea)
                SliverToBoxAdapter(
                  child: OutOfDeliveryAreaBanner(
                    nearestBranchName: branchProvider.nearestBranchOutOfRange?.name,
                    distanceKm: branchProvider.distanceToNearestKm,
                    onSwitchCity: () => branchProvider.selectCityFallback('Lahore'),
                  ),
                ),

              // 4. Closed Branch Temporary Fallback Notice
              if (branchProvider.closedBranchFallbackNotice != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              branchProvider.closedBranchFallbackNotice!,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 5. Search Bar Tap Target
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pushNamed('/search'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search burgers, pizzas, broast...',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.brandYellow.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune_rounded, size: 16, color: AppColors.brandMaroon),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 6. Mobile Horizontally Scrolling Category Chips
              if (isMobile)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categoriesWithAll.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, index) {
                        final cat = categoriesWithAll[index];
                        final isSelected = cat.toLowerCase() == _selectedRailCategory.toLowerCase();
                        final emoji = _getCategoryEmoji(cat);

                        return InkWell(
                          onTap: () => _onCategorySelected(cat),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandYellow
                                  : (isDark ? AppColors.darkSurfaceElevated : AppColors.surface),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.brandYellow
                                    : (isDark ? AppColors.darkBorder : AppColors.border),
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.brandMaroon
                                        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
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

              // 7. Active Admin Deals Carousel
              if (dealProvider.activeDeals.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: HomeDealsCarousel(
                      controller: _promoController,
                      currentIndex: _promoIndex,
                      deals: dealProvider.activeDeals,
                      onPageChanged: (idx) => setState(() => _promoIndex = idx),
                      onDealTap: (deal) {
                        context.read<CartProvider>().addDealToCart(deal);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${deal.title}" combo deal to cart!'),
                            backgroundColor: AppColors.success,
                            action: SnackBarAction(
                              label: 'View Cart',
                              textColor: Colors.white,
                              onPressed: () => Navigator.of(context).pushNamed('/cart'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // 8. Text Tabs: Popular / Recommended / New / All
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _textTabs.map((tab) {
                      final isSelected = _selectedTextTab == tab;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedTextTab = tab);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tab,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark ? AppColors.brandYellow : AppColors.brandMaroon)
                                      : (isDark ? AppColors.darkTextMuted : AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                height: 3,
                                width: isSelected ? 24 : 0,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.brandYellow : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 6)),

              // 9. Horizontal Filtered Dish Row
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: (menuProvider.isLoading && allFoods.isEmpty)
                      ? SizedBox(
                          height: 320,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 4,
                            separatorBuilder: (_, __) => const SizedBox(width: 14),
                            itemBuilder: (_, __) => const SizedBox(
                              width: 180,
                              child: FoodCardSkeleton(),
                            ),
                          ),
                        )
                      : filteredByRail.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                              child: EmptyStateView(
                                icon: Icons.fastfood_outlined,
                                title: 'No Dishes Found',
                                description: 'No items found matching $_selectedRailCategory / $_selectedTextTab.',
                              ),
                            )
                          : SizedBox(
                              height: 320,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filteredByRail.length,
                                itemBuilder: (context, index) {
                                  final food = filteredByRail[index];
                                  return ProductCard(
                                    food: food,
                                    onTap: () => Navigator.of(context).pushNamed(
                                      '/food-detail',
                                      arguments: food,
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ),

              // 10. "Popular" Section
              if (effectivePopularFoods.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Popular Dishes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/menu'),
                          child: Text(
                            'See all',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 320,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: effectivePopularFoods.length,
                      itemBuilder: (context, index) {
                        final food = effectivePopularFoods[index];
                        return ProductCard(
                          food: food,
                          heroTag: 'pop-food-${food.id}',
                          onTap: () => Navigator.of(context).pushNamed(
                            '/food-detail',
                            arguments: food,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // 11. "Recommended for you" Responsive Grid (2 columns on mobile, 3 on tablet)
              if (recommendedFoods.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⭐', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Recommended for you',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/menu'),
                          child: Text(
                            'See all',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet ? 3 : (isMobile ? 2 : 4),
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final food = recommendedFoods[index];
                        return ProductCard(
                          food: food,
                          inGrid: true,
                          heroTag: 'rec-food-${food.id}',
                          onTap: () => Navigator.of(context).pushNamed(
                            '/food-detail',
                            arguments: {
                              'food': food,
                              'heroTag': 'rec-food-${food.id}',
                            },
                          ),
                        );
                      },
                      childCount: recommendedFoods.length,
                    ),
                  ),
                ),
              ],

              // Bottom padding clearance above floating nav and cart pill
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: isMobile
            ? mainContent
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Side rail only when width >= 600
                  CategoryRail(
                    categories: categories,
                    selectedCategory: _selectedRailCategory,
                    onCategorySelected: _onCategorySelected,
                    onMenuTap: () => _openMenuDrawerSheet(context),
                    onSearchTap: () => Navigator.of(context).pushNamed('/search'),
                    onFilterTap: () => _openFilterSheet(context),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: ResponsiveTokens.dashboardMaxWidth),
                        child: mainContent,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
