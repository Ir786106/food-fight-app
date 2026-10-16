import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/menu_item_model.dart';

/// Interactive Size / Variant Selector component for FoodDetailScreen
class FoodDetailVariantSelector extends StatelessWidget {
  final List<MenuVariant> variants;
  final MenuVariant? selectedVariant;
  final ValueChanged<MenuVariant> onVariantChanged;

  const FoodDetailVariantSelector({
    super.key,
    required this.variants,
    required this.selectedVariant,
    required this.onVariantChanged,
  });

  String _getShortVariantLabel(String label) {
    final lower = label.trim().toLowerCase();
    if (lower == 'small' || lower == 's') return 'S';
    if (lower == 'medium' || lower == 'm') return 'M';
    if (lower == 'large' || lower == 'l') return 'L';
    if (lower == 'extra large' || lower == 'xl') return 'XL';
    if (lower == 'regular' || lower == 'reg') return 'Reg';
    if (lower == 'half') return 'Half';
    if (lower == 'full') return 'Full';
    if (label.length <= 4) return label;
    return label.substring(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Size / Variant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Text(
              'Required *',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: variants.map((variant) {
            final isSelected = selectedVariant?.label.toLowerCase() == variant.label.toLowerCase();
            return InkWell(
              key: ValueKey('variant_${variant.label}'),
              onTap: () => onVariantChanged(variant),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.brandYellow : AppColors.brandMaroon)
                      : (isDark ? AppColors.darkSurface : AppColors.surfaceMuted),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? AppColors.brandYellow : AppColors.brandMaroon)
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getShortVariantLabel(variant.label),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? (isDark ? AppColors.brandMaroon : Colors.white)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${variant.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? (isDark ? AppColors.brandMaroon : AppColors.brandYellow)
                            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
