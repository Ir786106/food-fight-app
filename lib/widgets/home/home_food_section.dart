import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_model.dart';
import '../food_card.dart';

/// Horizontal scrolling food section for "Popular" and "Recommended for you"
/// featuring circular-overflow product cards.
class HomeFoodSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<FoodModel> items;
  final ValueChanged<FoodModel> onItemTap;
  final VoidCallback? onSeeAll;

  const HomeFoodSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    required this.onItemTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          color: AppColors.brandMaroon,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: AppColors.brandMaroon,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Horizontal scrolling cards with overflowing circular food images
        SizedBox(
          height: 254,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final food = items[index];
              return FoodCard.vertical(
                food: food,
                onTap: () => onItemTap(food),
              );
            },
          ),
        ),
      ],
    );
  }
}
