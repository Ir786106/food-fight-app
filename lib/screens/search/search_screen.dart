import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/menu_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/responsive_layout.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _searchQuery = '';

  final List<String> _popularSearches = [
    'Burger',
    'Pizza',
    'Wings',
    'Fries',
    'Drink',
    'Shawarma',
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
    final categoryProvider = context.watch<CategoryProvider>();
    final menuProvider = context.watch<MenuProvider>();

    final categories = categoryProvider.activeCategories;
    final catMap = {for (var c in categories) c.id: c.name};

    final allFoods = menuProvider.activeItems.map((item) {
      final catName = catMap[item.categoryId] ?? item.categoryId;
      return FoodModel.fromMenuItem(item, categoryName: catName);
    }).toList();

    final results = _searchQuery.isEmpty
        ? <FoodModel>[]
        : allFoods.where((food) {
            final q = _searchQuery.toLowerCase();
            return food.name.toLowerCase().contains(q) ||
                food.description.toLowerCase().contains(q) ||
                food.category.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Search Food 🔍')),
      body: SafeArea(
        child: ResponsiveContainer.content(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                autofocus: false,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search delicious meals, pizza, burgers...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
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

                    if (_searchQuery.isEmpty) {
                      return ListView(
                        children: [
                          const Text(
                            'Popular Searches',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _popularSearches.map((tag) {
                              return ActionChip(
                                label: Text(tag),
                                backgroundColor: colorScheme.surface,
                                side: BorderSide(color: colorScheme.outlineVariant),
                                onPressed: () {
                                  _controller.text = tag;
                                  setState(() => _searchQuery = tag);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Trending Dishes 🥊',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          ...allFoods.take(4).map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: FoodCard(
                                  food: f,
                                  onTap: () => Navigator.of(context).pushNamed(
                                    '/food-detail',
                                    arguments: f,
                                  ),
                                ),
                              )),
                        ],
                      );
                    }

                    if (results.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.search_off_rounded,
                        title: 'No Dishes Found',
                        description: 'We couldn\'t find anything matching "$_searchQuery". Try another keyword!',
                      );
                    }

                    return ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final food = results[index];
                        return FoodCard(
                          food: food,
                          onTap: () => Navigator.of(context).pushNamed(
                            '/food-detail',
                            arguments: food,
                          ),
                        );
                      },
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
