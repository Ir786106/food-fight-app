import '../../core/localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_system.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/deal_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/food_model.dart';
import '../../widgets/common/offline_banner.dart';
import '../../widgets/home/home_filter_sheet.dart';
import '../../widgets/home/home_promo_carousel.dart';
import '../../widgets/home/product_card.dart';
import '../../widgets/skeleton/food_card_skeleton.dart';

class HomeScreen extends StatefulWidget {
  final ScrollController? parentScrollController;
  const HomeScreen({super.key, this.parentScrollController});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _promoController = PageController();
  String _category = 'All';
  bool _veg = false;
  bool _spicy = false;
  String _sort = 'popular';
  int _promoIndex = 0;
  String? _requestedBranch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BranchProvider>().autoResolveNearestBranch(context: context);
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _openCart() =>
      Navigator.of(context, rootNavigator: true).pushNamed('/cart');

  void _filters() =>
      HomeFilterSheet.show(context, isVeg: _veg, isSpicy: _spicy, sortBy: _sort,
          onApply: (veg, spicy, sort) {
        if (mounted) {
          setState(() {
            _veg = veg;
            _spicy = spicy;
            _sort = sort;
          });
        }
      });

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final branch = context.watch<BranchProvider>();
    final categories = context.watch<CategoryProvider>();
    final deals = context.watch<DealProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final theme = Theme.of(context);
    final branchId = branch.selectedBranch?.id;
    if (branchId != null && branchId != _requestedBranch) {
      _requestedBranch = branchId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        menu.watchMenuItems(branchId: branchId);
        deals.watchDeals(branchId: branchId, activeOnly: true);
      });
    }
    final categoryNames = {
      for (final c in categories.activeCategories) c.id: c.name
    };
    final items = menu.activeItems
        .where((item) =>
            (_category == 'All' ||
                categoryNames[item.categoryId] == _category) &&
            (!_veg || item.isVeg) &&
            (!_spicy || item.isSpicy))
        .toList();
    if (_sort == 'price_low') {
      items.sort((a, b) => a.minPrice.compareTo(b.minPrice));
    } else if (_sort == 'price_high') {
      items.sort((a, b) => b.minPrice.compareTo(a.minPrice));
    } else if (_sort == 'rating') {
      items.sort((a, b) => b.rating.compareTo(a.rating));
    }
    FoodModel food(dynamic item) => FoodModel.fromMenuItem(item,
        categoryName: categoryNames[item.categoryId] ?? '');
    final popular = items.where((item) => item.reviewCount > 0).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final recommended = items.where((item) => item.isFeatured).toList();
    final newest = [...items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait(
              [menu.fetchMenuItems(), categories.fetchCategories()]);
        },
        child: CustomScrollView(
          controller: widget.parentScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: Navigator.of(context).canPop(),
              title: Text(
                  user == null
                      ? 'Food Fight'
                      : 'Hello, ${user.name.split(' ').first}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              actions: [
                Selector<CartProvider, int>(
                  selector: (_, cart) => cart.itemCount,
                  builder: (_, count, __) => IconButton(
                    tooltip: 'Cart',
                    onPressed: _openCart,
                    icon: AnimatedSwitcher(
                      duration: DesignSystem.durationFast,
                      child: Badge(
                          key: ValueKey(count),
                          isLabelVisible: count > 0,
                          label: Text(count > 99 ? '99+' : count.toString()),
                          child: const Icon(Icons.shopping_bag_outlined)),
                    ),
                  ),
                ),
                Selector<NotificationProvider, int>(
                  selector: (_, notifications) => notifications.unreadCount,
                  builder: (_, count, __) => IconButton(
                    tooltip: 'Notifications',
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/notifications'),
                    icon: Badge(
                        isLabelVisible: count > 0,
                        child: const Icon(Icons.notifications_none_rounded)),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(
                    AppDimens.space48 * 2 + AppDimens.space16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                          child: TextButton.icon(
                        onPressed: () =>
                            branch.promptManualCitySelection(context),
                        icon: const Icon(Icons.location_on_outlined),
                        label: Text(branch.getDeliveryLabel(),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      )),
                      Selector<LoyaltyProvider, int>(
                        selector: (_, loyalty) => loyalty.tokensBalance,
                        builder: (_, points, __) => TextButton.icon(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/loyalty'),
                          icon: const Icon(Icons.stars_outlined),
                          label: Text(points.toString()),
                        ),
                      ),
                    ]),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/search'),
                        icon: const Icon(Icons.search),
                        label: Text(context.tr('Search the menu'),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      )),
                      IconButton(
                          tooltip: 'Filters',
                          onPressed: _filters,
                          icon: const Icon(Icons.tune)),
                    ]),
                    const SizedBox(height: AppDimens.space8),
                  ]),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: OfflineBanner()),
            if (branch.isOutOfDeliveryArea)
              SliverToBoxAdapter(
                  child: Padding(
                padding: DesignSystem.screenPadding,
                child: Text(
                    'Delivery is unavailable at your current location. Choose a supported area.',
                    style: theme.textTheme.bodyMedium),
              )),
            if (deals.activeDeals.isNotEmpty)
              SliverToBoxAdapter(
                  child: Padding(
                padding: DesignSystem.screenPadding,
                child: HomeDealsCarousel(
                    controller: _promoController,
                    currentIndex: _promoIndex,
                    deals: deals.activeDeals,
                    onPageChanged: (index) =>
                        setState(() => _promoIndex = index),
                    onDealTap: (deal) {
                      context.read<CartProvider>().addDealToCart(deal);
                      AppSnackbar.showSuccess(context, 'Added to cart',
                          action: SnackBarAction(
                              label: 'View', onPressed: _openCart));
                    }),
              )),
            SliverToBoxAdapter(
                child: SizedBox(
              height: AppDimens.buttonHeight + AppDimens.space16,
              child: ListView.separated(
                padding: DesignSystem.screenPadding,
                scrollDirection: Axis.horizontal,
                itemCount: categories.activeCategories.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppDimens.space8),
                itemBuilder: (_, index) {
                  final name = index == 0
                      ? 'All'
                      : categories.activeCategories[index - 1].name;
                  return ChoiceChip(
                      label: Text(name),
                      selected: _category == name,
                      onSelected: (_) => setState(() => _category = name));
                },
              ),
            )),
            if (_veg || _spicy || _category != 'All' || _sort != 'popular')
              SliverToBoxAdapter(
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                          onPressed: () => setState(() {
                                _veg = false;
                                _spicy = false;
                                _category = 'All';
                                _sort = 'popular';
                              }),
                          child: Text(context.tr('Clear all filters'))))),
            if (menu.isLoading && items.isEmpty)
              SliverToBoxAdapter(
                  child: SizedBox(
                      height: AppDimens.space48 * 7,
                      child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: DesignSystem.screenPadding,
                          itemCount: 3,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppDimens.space8),
                          itemBuilder: (_, __) => const SizedBox(
                              width: AppDimens.foodCardWidth,
                              child: FoodCardSkeleton()))))
            else if (menu.errorMessage != null && items.isEmpty)
              SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                      message: menu.errorMessage!,
                      onRetry: menu.fetchMenuItems))
            else if (items.isEmpty)
              SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                      icon: Icons.restaurant_menu,
                      title: branchId == null
                          ? 'Choose your area'
                          : 'No dishes found',
                      description: branchId == null
                          ? 'Select a delivery area to browse your local kitchen.'
                          : 'Try another category or clear your filters.',
                      buttonText:
                          branchId == null ? 'Choose area' : 'Clear filters',
                      onButtonPressed: () {
                        if (branchId == null) {
                          branch.promptManualCitySelection(context);
                        } else {
                          setState(() {
                            _category = 'All';
                            _veg = false;
                            _spicy = false;
                          });
                        }
                      }))
            else ...[
              if (popular.isNotEmpty)
                ..._section('Popular Dishes',
                    popular.take(8).map(food).toList(), 'popular'),
              if (recommended.isNotEmpty)
                ..._section('Recommended',
                    recommended.take(8).map(food).toList(), 'recommended'),
              ..._section(
                  'New on the menu', newest.take(8).map(food).toList(), 'new'),
              if (_category != 'All' || _sort != 'popular')
                ..._section(
                    'Browse dishes', items.map(food).toList(), 'browse'),
            ],
            SliverToBoxAdapter(
                child: SizedBox(height: AppInsets.bottomBarClearance(context))),
          ],
        ),
      ),
    );
  }

  List<Widget> _section(String title, List<FoodModel> foods, String tag) => [
        SliverToBoxAdapter(
            child: Padding(
                padding: DesignSystem.screenPadding,
                child: Row(children: [
                  Expanded(
                      child: Text(title,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis)),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed('/menu'),
                      child: Text(context.tr('See all'))),
                ]))),
        SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
            sliver: SliverLayoutBuilder(builder: (context, constraints) {
              final columns = constraints.crossAxisExtent >= 840
                  ? 4
                  : constraints.crossAxisExtent >= 600
                      ? 3
                      : 2;
              final tileWidth =
                  (constraints.crossAxisExtent - AppDimens.space8 * (columns - 1)) /
                      columns;
              final imageHeight = (tileWidth - AppDimens.space8) / 1.5;
              final textHeight = MediaQuery.textScalerOf(context).scale(80);
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppDimens.space8,
                    crossAxisSpacing: AppDimens.space8,
                    mainAxisExtent: imageHeight + textHeight + 112),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = foods[index];
                  final hero = '$tag-${item.id}';
                  return ProductCard(
                      food: item,
                      inGrid: true,
                      heroTag: hero,
                      onTap: () => Navigator.of(context).pushNamed(
                          '/food-detail',
                          arguments: {'food': item, 'heroTag': hero}));
                }, childCount: foods.length),
              );
            })),
      ];
}
