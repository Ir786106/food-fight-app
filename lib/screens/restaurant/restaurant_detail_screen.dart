import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant_model.dart';
import '../../models/food_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/responsive_layout.dart';

class RestaurantDetailScreen extends StatelessWidget {
  const RestaurantDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final restaurant =
        ModalRoute.of(context)?.settings.arguments as RestaurantModel? ??
            RestaurantModel(
              id: 'food_fight_hq',
              name: 'Food Fight Restaurant',
              cuisine: 'Fast Food • Burgers • Pizza',
              rating: 4.8,
              deliveryTimeMinutes: 25,
              deliveryFee: 150,
              imageEmoji: '🥊',
              address: 'Food Fight HQ, Main Boulevard',
            );
    final cart = context.watch<CartProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final activeItems = menuProvider.activeItems;

    return Scaffold(
      body: ResponsiveContainer.content(
        maxWidth: 860,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textPrimary, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  alignment: Alignment.center,
                  child: Text(restaurant.imageEmoji,
                      style: const TextStyle(fontSize: 90)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      restaurant.cuisine,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _infoChip(Icons.star, '${restaurant.rating}',
                            AppColors.accent),
                        const SizedBox(width: 10),
                        _infoChip(Icons.timer_outlined,
                            '${restaurant.deliveryTimeMinutes} min', Colors.blue),
                        const SizedBox(width: 10),
                        _infoChip(Icons.delivery_dining,
                            'Rs. ${restaurant.deliveryFee.toStringAsFixed(0)}', AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurant.address,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text('Full Menu',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 17)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (menuProvider.isLoading && activeItems.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: LoadingIndicator(message: 'Loading menu items...'),
                ),
              )
            else if (menuProvider.errorMessage != null && activeItems.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: ErrorView(
                    message: menuProvider.errorMessage!,
                    onRetry: () => menuProvider.fetchMenuItems(),
                  ),
                ),
              )
            else if (activeItems.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: EmptyStateView(
                    icon: Icons.fastfood_rounded,
                    title: 'No Dishes Available',
                    description: 'Please check back soon for delicious new additions!',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = activeItems[index];
                      final food = FoodModel.fromMenuItem(item);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FoodCard(
                          food: food,
                          onTap: () => Navigator.of(context).pushNamed(
                            '/food-detail',
                            arguments: food,
                          ),
                        ),
                      );
                    },
                    childCount: activeItems.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: cart.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cart.itemCount} items in cart',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          'Rs. ${cart.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pushNamed('/cart'),
                      child: const Text('View Cart 🥊', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
