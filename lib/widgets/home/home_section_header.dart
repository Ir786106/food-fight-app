import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable Section Header with optional leading emoji/icon and trailing action
class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? emoji;
  final IconData? icon;
  final String actionLabel;
  final VoidCallback? onActionTap;

  const HomeSectionHeader({
    super.key,
    required this.title,
    this.emoji,
    this.icon,
    this.actionLabel = 'See all',
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null && emoji!.isNotEmpty) ...[
                  Text(emoji!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                ] else if (icon != null) ...[
                  Icon(icon, size: 18, color: AppColors.brandYellow),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (onActionTap != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
