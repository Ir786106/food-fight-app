import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/menu_provider.dart';
import '../../models/food_model.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/responsive_layout.dart';

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

  static const List<IconData> _categoryIcons = [
    Icons.fastfood,
    Icons.local_pizza,
    Icons.auto_awesome,
    Icons.emoji_food_beverage,
    Icons.local_dining,
    Icons.lunch_dining,
    Icons.local_fire_department,
    Icons.layers,
    Icons.ramen_dining,
    Icons.restaurant,
  ];

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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final menuProvider = context.watch<MenuProvider>();

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

    return Scaffold(
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
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.textSecondary.withValues(alpha: 0.10),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  AppConstants.logoIconPath,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Deliver to',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, color: AppColors.primary, size: 16),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Food Fight Express Zone',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Admin Portal shortcut button for admin user
                            if (auth.isAdmin)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () => Navigator.of(context).pushNamed('/admin/dashboard'),
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
                                        Text('Admin', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.onSurface),
                                onPressed: () => Navigator.of(context).pushNamed('/notifications'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Greeting
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                        child: Text(
                          'Ready for a meal battle, $firstName? 🥊',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),

                    // Search Bar Tap Trigger
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/search'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: AppColors.textSecondary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Search menu items or food battle deals...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Promo Banner Carousel
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                        child: SizedBox(
                          height: 140,
                          child: PageView(
                            controller: _promoController,
                            onPageChanged: (index) => setState(() => _promoIndex = index),
                            children: [
                              _buildPromoCard('Fight Club Platter Deal', 'Rs. 849', '🍗', context),
                              _buildPromoCard('Buy 1 Get 1 Shawarma', 'Code: FIGHTBOGO', '🥙', context),
                              _buildPromoCard('Cheese Burst Pizza Combo', 'Special Battle Deal', '🍕', context),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Categories Horizontal Bar
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
                        child: Text(
                          'Menu Categories',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: categoryNames.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = categoryNames[index];
                            final isSelected = cat == _selectedCategory;
                            final icon = _categoryIcons[index % _categoryIcons.length];

                            return GestureDetector(
                              onTap: () => setState(() => _selectedCategory = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(icon, color: isSelected ? Colors.white : AppColors.primary, size: 15),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
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

                    // Food Items Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedCategory == 'All' ? 'All Dishes' : _selectedCategory,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${filteredFoods.length} items',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Food Grid / List
                    if (filteredFoods.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: EmptyStateView(
                            icon: Icons.fastfood_outlined,
                            title: 'No Dishes Found',
                            description: _selectedCategory == 'All'
                                ? 'No food items are currently listed on the menu.'
                                : 'No dishes currently available in the "$_selectedCategory" category.',
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
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final food = filteredFoods[index];
                              return FoodCard(
                                food: food,
                                onTap: () => Navigator.of(context).pushNamed('/food-detail', arguments: food),
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
                                onTap: () => Navigator.of(context).pushNamed('/food-detail', arguments: food),
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

  Widget _buildPromoCard(String title, String subtitle, String emoji, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFFF5722)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
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
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'HOT DEAL 🥊',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
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
