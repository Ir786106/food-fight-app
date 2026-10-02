import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Category filter rendered as clean, plain text tabs with a short rounded
/// yellow underline under the active tab instead of heavy chips (Ref A).
class HomeCategoryTabs extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;

  const HomeCategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.toLowerCase() == selectedCategory.toLowerCase();

          return GestureDetector(
            onTap: () => onSelectCategory(category),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Plain Text Tab Label
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon)
                        : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                  ),
                ),

                const SizedBox(height: 5),

                // Short rounded yellow underline under the active tab
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: isSelected ? 24 : 0,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.brandYellow : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
