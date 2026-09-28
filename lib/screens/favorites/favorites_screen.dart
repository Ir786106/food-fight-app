import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/food_card.dart';
import '../../widgets/common/responsive_layout.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final favorites = cart.favorites;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Saved Favorites ❤️'),
            if (favorites.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${favorites.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveContainer.content(
          maxWidth: 860,
          child: favorites.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_border_rounded, size: 72, color: AppColors.primary),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No Favorites Yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the heart icon on any dish or restaurant to quickly access your favorite meals here!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
                              }
                            },
                            child: const Text('Discover Food 🍔'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final food = favorites[index];
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
    );
  }
}
