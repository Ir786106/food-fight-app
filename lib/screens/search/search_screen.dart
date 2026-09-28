import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_model.dart';
import '../../models/restaurant_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/menu_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_card.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../providers/restaurant_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _popularSearches = [
    'Burgers',
    'Pizza',
    'Wings',
    'Shawarma',
    'Platter',
    'Fries',
    'Drinks',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final categoryProvider = context.watch<CategoryProvider>();
    final menuProvider = context.watch<MenuProvider>();

    final categories = categoryProvider.activeCategories;
    final catMap = {for (var c in categories) c.id: c.name};

    final allFoods = menuProvider.activeItems.map((item) {
      final catName = catMap[item.categoryId] ?? item.categoryId;
      return FoodModel.fromMenuItem(item, categoryName: catName);
    }).toList();

    final allRestaurants = context.watch<RestaurantProvider>().restaurants;

    // Filter dishes
    final foodResults = _searchQuery.isEmpty
        ? <FoodModel>[]
        : allFoods.where((food) {
            final q = _searchQuery.toLowerCase();
            final matchesQuery = food.name.toLowerCase().contains(q) ||
                food.description.toLowerCase().contains(q) ||
                food.category.toLowerCase().contains(q);
            final matchesFilter = _selectedFilter == 'All' ||
                food.category.toLowerCase() == _selectedFilter.toLowerCase();
            return matchesQuery && matchesFilter;
          }).toList();

    // Filter restaurants
    final restaurantResults = _searchQuery.isEmpty
        ? <RestaurantModel>[]
        : allRestaurants.where((r) {
            final q = _searchQuery.toLowerCase();
            return r.name.toLowerCase().contains(q) ||
                r.cuisine.toLowerCase().contains(q) ||
                r.address.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Search Dishes & Kitchens 🔍'),
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveContainer.content(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Search Input Bar
              Container(
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
                child: TextField(
                  controller: _controller,
                  autofocus: false,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search delicious meals, pizza, burgers...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.cancel_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: Builder(
                  builder: (context) {
                    if (menuProvider.isLoading && allFoods.isEmpty) {
                      return const LoadingIndicator(message: 'Searching live menu...');
                    }

                    if (menuProvider.errorMessage != null && allFoods.isEmpty) {
                      return ErrorView(
                        message: 'Unable to load menu items at this moment.',
                        onRetry: () {
                          categoryProvider.fetchCategories();
                          menuProvider.fetchMenuItems();
                        },
                      );
                    }

                    // Mode 1: Empty Query - Show Popular Searches & "Top Restaurants / Dishes Near You"
                    if (_searchQuery.isEmpty) {
                      return ListView(
                        children: [
                          Text(
                            'Popular Searches',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: _popularSearches.map((tag) {
                              return ActionChip(
                                label: Text(tag),
                                labelStyle: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                                backgroundColor: colorScheme.surface,
                                side: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onPressed: () {
                                  _controller.text = tag;
                                  setState(() => _searchQuery = tag);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Top Restaurants Near You
                          Text(
                            'Top Restaurants Near You 🏆',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 255,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: allRestaurants.length,
                              itemBuilder: (context, index) {
                                final restaurant = allRestaurants[index];
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
                          const SizedBox(height: 24),

                          // Top Dishes Near You
                          Text(
                            'Top Dishes Near You 🔥',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...allFoods.take(5).map((f) => FoodCard(
                                food: f,
                                onTap: () => Navigator.of(context).pushNamed(
                                  '/food-detail',
                                  arguments: f,
                                ),
                              )),
                        ],
                      );
                    }

                    // Mode 2: Search Query with Results
                    if (foodResults.isEmpty && restaurantResults.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.search_off_rounded,
                        title: 'No Results Found',
                        description:
                            'We couldn\'t find any dish or restaurant matching "$_searchQuery". Try another keyword!',
                        buttonText: 'Clear Search',
                        onButtonPressed: () {
                          _controller.clear();
                          setState(() => _searchQuery = '');
                        },
                      );
                    }

                    return ListView(
                      children: [
                        // Restaurant matches if any
                        if (restaurantResults.isNotEmpty) ...[
                          Text(
                            'Matching Kitchens (${restaurantResults.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...restaurantResults.map((r) => RestaurantCard(
                                restaurant: r,
                                isHorizontal: false,
                                onTap: () => Navigator.of(context).pushNamed(
                                  '/restaurant-detail',
                                  arguments: r,
                                ),
                              )),
                          const SizedBox(height: 16),
                        ],

                        // Food item matches if any
                        if (foodResults.isNotEmpty) ...[
                          Text(
                            'Matching Dishes (${foodResults.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...foodResults.map((food) => FoodCard(
                                food: food,
                                onTap: () => Navigator.of(context).pushNamed(
                                  '/food-detail',
                                  arguments: food,
                                ),
                              )),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
