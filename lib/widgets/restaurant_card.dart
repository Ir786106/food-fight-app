import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../theme/app_theme.dart';

class RestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback onTap;
  final bool isHorizontal;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: isHorizontal ? 240 : double.infinity,
      margin: EdgeInsets.only(
        right: isHorizontal ? 14 : 0,
        bottom: isHorizontal ? 4 : 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Hero / Emoji Banner
              Stack(
                children: [
                  Container(
                    height: isHorizontal ? 112 : 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.15),
                          colorScheme.surfaceContainerHighest,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  alignment: Alignment.center,
                  child: Text(
                    restaurant.imageEmoji,
                    style: TextStyle(fontSize: isHorizontal ? 48 : 56),
                  ),
                ),
                // Closed overlay
                if (!restaurant.isOpen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          'Closed',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Featured badge
                if (restaurant.isFeatured)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 12, color: Color(0xFF181820)),
                          SizedBox(width: 3),
                          Text(
                            'Featured',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF181820),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Delivery fee tag
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      restaurant.deliveryFee == 0
                          ? 'Free Delivery'
                          : 'Rs. ${restaurant.deliveryFee.toStringAsFixed(0)} Delivery',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.cuisine,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              '${restaurant.rating}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time
                      Icon(Icons.access_time_rounded, color: colorScheme.onSurfaceVariant, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${restaurant.deliveryTimeMinutes} min',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
