import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Form switches for toggling availability, vegetarian, spicy, and featured status of menu items
class MenuItemAvailabilitySwitches extends StatelessWidget {
  final bool isAvailable;
  final bool isFeatured;
  final bool isSpicy;
  final bool isVeg;
  final ValueChanged<bool> onAvailableChanged;
  final ValueChanged<bool> onFeaturedChanged;
  final ValueChanged<bool> onSpicyChanged;
  final ValueChanged<bool> onVegChanged;

  const MenuItemAvailabilitySwitches({
    super.key,
    required this.isAvailable,
    required this.isFeatured,
    required this.isSpicy,
    required this.isVeg,
    required this.onAvailableChanged,
    required this.onFeaturedChanged,
    required this.onSpicyChanged,
    required this.onVegChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item Status & Attributes',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Available in Kitchen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Show item to customers for ordering', style: TextStyle(fontSize: 12)),
            value: isAvailable,
            activeTrackColor: AppColors.brandYellow,
            contentPadding: EdgeInsets.zero,
            onChanged: onAvailableChanged,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Featured on Home Screen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Highlight item in signature dish carousel', style: TextStyle(fontSize: 12)),
            value: isFeatured,
            activeTrackColor: AppColors.brandYellow,
            contentPadding: EdgeInsets.zero,
            onChanged: onFeaturedChanged,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Spicy (🌶️)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Show spice level badge and customizer', style: TextStyle(fontSize: 12)),
            value: isSpicy,
            activeTrackColor: AppColors.tomato,
            contentPadding: EdgeInsets.zero,
            onChanged: onSpicyChanged,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Vegetarian (🌱)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Mark as plant-based vegetarian dish', style: TextStyle(fontSize: 12)),
            value: isVeg,
            activeTrackColor: AppColors.lettuce,
            contentPadding: EdgeInsets.zero,
            onChanged: onVegChanged,
          ),
        ],
      ),
    );
  }
}
