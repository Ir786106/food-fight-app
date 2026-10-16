import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/menu_item_model.dart';

/// Interactive Addons & Extras Selector component for FoodDetailScreen
class FoodDetailAddonsSelector extends StatelessWidget {
  final List<MenuAddon> addons;
  final Set<MenuAddon> selectedAddons;
  final ValueChanged<MenuAddon> onToggleAddon;

  const FoodDetailAddonsSelector({
    super.key,
    required this.addons,
    required this.selectedAddons,
    required this.onToggleAddon,
  });

  @override
  Widget build(BuildContext context) {
    if (addons.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add-ons & Extras',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Text(
              'Optional',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: addons.map((addon) {
            final isSelected = selectedAddons.contains(addon);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.darkYellowSoft : AppColors.yellowSoft)
                    : (isDark ? AppColors.darkSurface : AppColors.surface),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.brandYellow
                      : (isDark ? AppColors.darkBorder : AppColors.border),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: CheckboxListTile(
                value: isSelected,
                activeColor: AppColors.brandYellow,
                checkColor: AppColors.brandMaroon,
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: Text(
                  addon.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                secondary: Text(
                  '+ Rs. ${addon.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? (isDark ? AppColors.brandYellow : AppColors.brandMaroon)
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                ),
                onChanged: (_) => onToggleAddon(addon),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
