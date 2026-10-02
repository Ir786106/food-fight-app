import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/deal_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/branch_model.dart';
import '../../models/food_model.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/home/category_rail.dart';
import '../../widgets/home/product_card.dart';
import '../../widgets/home/home_promo_carousel.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_view.dart';


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
    _contentScrollController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String categoryName) {
    setState(() {
      _selectedRailCategory = categoryName;
    });
    // Scroll content to top on category change
    if (_contentScrollController.hasClients) {
      _contentScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
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
                backgroundColor: AppColors.brandYellow,
                foregroundColor: AppColors.brandMaroon,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                cart.clearCart();
                _applyBranchSelection(branch);
              },
              child: const Text(
                'Clear Cart & Switch',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
    context.read<DealProvider>().watchDeals(branchId: branch.id);
  }

  void _openBranchSelectionSheet(BuildContext context) {
    final branchProv = context.read<BranchProvider>();
    final activeBranches = branchProv.activeBranches;
    final selectedBranch = branchProv.selectedBranch;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Food Fight Branch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                            ? AppColors.yellowSoft.withValues(alpha: 0.5)
                            : (isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceMuted),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandYellow
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isSelected ? AppColors.brandYellow : AppColors.yellowSoft,
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: AppColors.brandMaroon,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  branch.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${branch.city} • ${branch.address}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                            color: isSelected ? AppColors.brandMaroon : AppColors.textMuted,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMenuDrawerSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.brandYellow,
                    child: Icon(Icons.person_rounded, color: AppColors.brandMaroon, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentUser?.name ?? 'Food Fighter',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          auth.currentUser?.email ?? 'fighter@foodfight.pk',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _drawerItem(
                icon: Icons.location_on_outlined,
                title: 'Saved Addresses',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/addresses');
                },
                isDark: isDark,
              ),
              _drawerItem(
                icon: Icons.storefront_outlined,
                title: 'Switch Branch',
                onTap: () {
                  Navigator.pop(ctx);
                  _openBranchSelectionSheet(context);
                },
                isDark: isDark,
              ),
              _drawerItem(
                icon: Icons.favorite_border_rounded,
                title: 'My Favorites',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/favorites');
                },
                isDark: isDark,
              ),
              _drawerItem(
                icon: Icons.receipt_long_outlined,
                title: 'Order History',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/order-history');
                },
                isDark: isDark,
              ),
              _drawerItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/settings');
                },
                isDark: isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDark ? AppColors.brandYellow : AppColors.brandMaroon),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _openFilterSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter & Sort Dishes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _filterOnlyVeg = false;
                            _filterOnlySpicy = false;
                            _sortBy = 'popular';
                          });
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                        child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Toggles
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
                      foregroundColor: AppColors.onYellow,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final branchProvider = context.watch<BranchProvider>();
    final dealProvider = context.watch<DealProvider>();
    final addressProvider = context.watch<AddressProvider?>();
    final notifProvider = context.watch<NotificationProvider?>();

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

    final allFoods = menuProvider.activeItems.map((item) {
      final catName = catMap[item.categoryId] ?? item.categoryId;
      return FoodModel.fromMenuItem(item, categoryName: catName);
    }).toList();

    // 1. Filter by category rail
    List<FoodModel> filteredByRail = _selectedRailCategory == 'All'
        ? allFoods
        : allFoods.where((f) => f.category.toLowerCase() == _selectedRailCategory.toLowerCase()).toList();

    // 2. Filter by text tab (Popular, Recommended, New, All)
    if (_selectedTextTab == 'Popular') {
      filteredByRail = filteredByRail.where((f) => f.rating >= 4.4).toList();
    } else if (_selectedTextTab == 'Recommended') {
      filteredByRail = filteredByRail.reversed.toList();
    } else if (_selectedTextTab == 'New') {
      filteredByRail = filteredByRail.take(6).toList();
    }

    // 3. Filter by sheet options
    if (_filterOnlyVeg) {
      filteredByRail = filteredByRail.where((f) => f.isVeg).toList();
    }
    if (_filterOnlySpicy) {
      filteredByRail = filteredByRail.where((f) => f.isSpicy).toList();
    }

    // 4. Sort
    if (_sortBy == 'price_low') {
      filteredByRail.sort((a, b) => a.startingPrice.compareTo(b.startingPrice));
    } else if (_sortBy == 'price_high') {
      filteredByRail.sort((a, b) => b.startingPrice.compareTo(a.startingPrice));
    } else if (_sortBy == 'rating') {
      filteredByRail.sort((a, b) => b.rating.compareTo(a.rating));
    }

    // High-rated items for "Popular" section
    final popularFoods = allFoods.where((f) => f.rating >= 4.4).toList();
    final effectivePopularFoods = popularFoods.isNotEmpty ? popularFoods : allFoods.take(6).toList();

    // Recommended for you list
    final recommendedFoods = allFoods.reversed.take(6).toList();

    final hasUnreadNotifications = (notifProvider?.unreadCount ?? 0) > 0;
    final currentAddressTitle = addressProvider?.defaultAddress?.label ?? 'Select Address';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Left Vertical Category Rail (Reference A)
            CategoryRail(
              categories: categories,
              selectedCategory: _selectedRailCategory,
              onCategorySelected: _onCategorySelected,
              onMenuTap: () => _openMenuDrawerSheet(context),
              onSearchTap: () => Navigator.of(context).pushNamed('/search'),
              onFilterTap: () => _openFilterSheet(context),
            ),

            // 2. Right Content Area (White / Background Surface)
            Expanded(
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
                        // Top Row: Address chip + Branch chip + Bell + Heart
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                            child: Row(
                              children: [
                                // Delivery address chip
                                Expanded(
                                  child: InkWell(
                                    onTap: () => Navigator.of(context).pushNamed('/addresses'),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark ? AppColors.darkBorder : AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.location_on_rounded,
                                            color: AppColors.tomato,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              currentAddressTitle,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Branch selector chip
                                InkWell(
                                  onTap: () => _openBranchSelectionSheet(context),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? AppColors.darkBorder : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.storefront_rounded,
                                          color: AppColors.brandMaroon,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          selectedBranch?.name ?? 'Branch',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Loyalty tokens chip
                                InkWell(
                                  onTap: () => Navigator.of(context).pushNamed('/profile'),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandYellow.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🎁', style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${context.watch<LoyaltyProvider>().balance}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? AppColors.brandYellow : AppColors.onYellow,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Heart (Favorites)
                                IconButton(
                                  icon: const Icon(Icons.favorite_border_rounded, size: 22),
                                  color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                  tooltip: 'Favorites',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  onPressed: () => Navigator.of(context).pushNamed('/favorites'),
                                ),

                                // Bell (Notifications) with unread dot
                                Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.notifications_none_rounded, size: 22),
                                      color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                      tooltip: 'Notifications',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      onPressed: () => Navigator.of(context).pushNamed('/notifications'),
                                    ),
                                    if (hasUnreadNotifications)
                                      Positioned(
                                        top: 6,
                                        right: 6,
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

                        const SliverToBoxAdapter(child: SizedBox(height: 8)),

                        // Heading: "Find your" (light) / "favourite foods" (bold 28) (Ref A)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Find your',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w400,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                                    letterSpacing: -0.3,
                                    height: 1.15,
                                  ),
                                ),
                                Text(
                                  'favourite foods',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 12)),

                        // Deals Carousel
                        if (dealProvider.activeDeals.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
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

                        // Text Tabs: Popular / Recommended / New / All with 3px yellow underline (Ref A)
                        SliverToBoxAdapter(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
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
                                                ? (isDark ? AppColors.brandYellow : AppColors.textPrimary)
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

                        const SliverToBoxAdapter(child: SizedBox(height: 10)),

                        // Animated cross-fade for products
                        SliverToBoxAdapter(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: filteredByRail.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                                    child: EmptyStateView(
                                      icon: Icons.fastfood_outlined,
                                      title: 'No Dishes Found',
                                      description: 'No items found matching $_selectedRailCategory / $_selectedTextTab.',
                                    ),
                                  )
                                : SizedBox(
                                    height: 250,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
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

                        const SliverToBoxAdapter(child: SizedBox(height: 18)),

                        // "Recommended for you" Section (Ref A)
                        if (recommendedFoods.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recommended for you',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon,
                                    ),
                                  ),
                                  Text(
                                    'See all',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 240,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                itemCount: recommendedFoods.length,
                                itemBuilder: (context, index) {
                                  final food = recommendedFoods[index];
                                  return ProductCard(
                                    food: food,
                                    heroTag: 'rec-food-${food.id}',
                                    onTap: () => Navigator.of(context).pushNamed(
                                      '/food-detail',
                                      arguments: food,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 18)),
                        ],

                        // "Popular" Section (Master prompt Part 2)
                        if (effectivePopularFoods.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Popular',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon,
                                    ),
                                  ),
                                  Text(
                                    '${effectivePopularFoods.length} items',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 240,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                          const SliverToBoxAdapter(child: SizedBox(height: 20)),
                        ],

                        // Bottom padding for scroll clearance above floating nav and cart pill
                        const SliverToBoxAdapter(child: SizedBox(height: 110)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
