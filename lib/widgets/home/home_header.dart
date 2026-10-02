import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/branch_model.dart';

/// Top header of HomeScreen following Ref A:
/// - Two-tone large heading (light grey first line + bold dark second line)
/// - Delivery branch selector pill
/// - Search bar triggering /search
class HomeHeader extends StatelessWidget {
  final String userName;
  final BranchModel? selectedBranch;
  final VoidCallback onBranchTap;
  final VoidCallback onSearchTap;
  final VoidCallback onChatTap;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.selectedBranch,
    required this.onBranchTap,
    required this.onSearchTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: Branch location selector + Support chat action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Branch location selector pill
              GestureDetector(
                onTap: onBranchTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.brandYellow,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        selectedBranch?.name ?? 'Select Branch',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // Chat with Support Action Button
              Semantics(
                button: true,
                label: 'Support Chat',
                child: InkWell(
                  onTap: onChatTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.brandMaroon,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Two-Tone Large Heading (Ref A)
          // Light grey first line + Bold dark second line
          Text(
            'Find your',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              letterSpacing: -0.2,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'favourite foods 🥊',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.brandMaroon,
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 18),

          // Search Bar
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search burgers, pizza, shawarma...',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.yellowSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.brandMaroon,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
