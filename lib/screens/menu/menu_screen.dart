import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/responsive_layout.dart';

class MenuScreen extends StatefulWidget {
  final VoidCallback? onNavigateToCart;

  const MenuScreen({super.key, this.onNavigateToCart});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _onlySpicy = false;

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
  };

  String _getCategoryEmoji(String categoryName) {
    final lower = categoryName.toLowerCase().trim();
    for (final entry in _categoryEmojiMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return '🍲';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cart = context.watch<CartProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final menuProvider = context.watch<MenuProvider>();

    final categories = categoryProvider.activeCategories;
    final catNames = ['All', ...categories.map((c) => c.name)];
    final catMap = {for (var c in categories) c.id: c.name};

    final allFoods = menuProvider.activeItems.map((item) {
      final catName = catMap[item.categoryId] ?? item.categoryId;
      return FoodModel.fromMenuItem(item, categoryName: catName);
    }).toList();

    // Filter by category
    var filtered = _selectedCategory == 'All'
        ? allFoods
        : allFoods.where((f) => f.category == _selectedCategory).toList();

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((f) =>
              f.name.toLowerCase().contains(q) ||
              f.description.toLowerCase().contains(q))
          .toList();
    }

    // Filter by spicy
    if (_onlySpicy) {
      filtered = filtered.where((f) => f.isSpicy).toList();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Text('Food Menu 🥊'),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 24),
                if (cart.itemCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Center(
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              if (widget.onNavigateToCart != null) {
                widget.onNavigateToCart!();
              } else {
                Navigator.of(context).pushNamed('/cart');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer.content(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search input
              TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search dishes or ingredients...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Categories Horizontal Scroll
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: catNames.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = catNames[index];
                    final isSelected = cat == _selectedCategory;
                    final emoji = _getCategoryEmoji(cat);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
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
              const SizedBox(height: 12),

              // Filter Chips Row
              Row(
                children: [
                  FilterChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🌶️ Spicy Only'),
                      ],
                    ),
                    selected: _onlySpicy,
                    onSelected: (val) => setState(() => _onlySpicy = val),
                    backgroundColor: colorScheme.surface,
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _onlySpicy ? AppColors.primary : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _onlySpicy ? AppColors.primary : colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${filtered.length} dishes',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Items View
              Expanded(
                child: menuProvider.isLoading && allFoods.isEmpty
                    ? const LoadingIndicator(message: 'Loading fresh menu items...')
                    : menuProvider.errorMessage != null && allFoods.isEmpty
                        ? ErrorView(
                            message: menuProvider.errorMessage!,
                            onRetry: () {
                              categoryProvider.fetchCategories();
                              menuProvider.fetchMenuItems();
                            },
                          )
                        : filtered.isEmpty
                            ? EmptyStateView(
                                icon: Icons.lunch_dining_outlined,
                                title: 'No Dishes Found',
                                description: _searchQuery.isNotEmpty
                                    ? 'No matches found for "$_searchQuery".'
                                    : 'There are no dishes matching your current filter.',
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await categoryProvider.fetchCategories();
                                  await menuProvider.fetchMenuItems();
                                },
                                child: MediaQuery.sizeOf(context).width >= 720
                                    ? GridView.builder(
                                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 440,
                                          mainAxisExtent: 130,
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 12,
                                        ),
                                        itemCount: filtered.length,
                                        itemBuilder: (context, index) {
                                          final food = filtered[index];
                                          return FoodCard(
                                            food: food,
                                            onTap: () => Navigator.of(context).pushNamed(
                                              '/food-detail',
                                              arguments: food,
                                            ),
                                          );
                                        },
                                      )
                                    : ListView.separated(
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final food = filtered[index];
                                          return FoodCard(
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
            ],
          ),
        ),
      ),
    );
  }
}
