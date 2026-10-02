import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../common/network_image_view.dart';

/// Vertical yellow side rail for category navigation (Ref A & Ref C).
/// Every category displays an icon/image and a clear 11px label below.
/// The active category sits in a curved notch/bump with a ring accent.
class CategorySideRail extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final String Function(String) getCategoryEmoji;
  final String? Function(String)? getCategoryImageUrl;
  final VoidCallback? onToggleCollapse;
  final bool isPermanent;

  const CategorySideRail({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.getCategoryEmoji,
    this.getCategoryImageUrl,
    this.onToggleCollapse,
    this.isPermanent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const railBgColor = AppColors.brandYellow;
    final screenBgColor = theme.scaffoldBackgroundColor;

    return Container(
      width: 78,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: railBgColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppDimens.radius24),
          bottomRight: Radius.circular(AppDimens.radius24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 14,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Rail Header: Toggle button (on mobile) or branding icon
          if (!isPermanent && onToggleCollapse != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: IconButton(
                icon: const Icon(
                  Icons.menu_open_rounded,
                  color: AppColors.onYellow,
                  size: 20,
                ),
                tooltip: 'Hide Category Rail',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onToggleCollapse!();
                },
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.onYellow,
                size: 22,
              ),
            ),

          // Scrollable Category Icons List with 11px labels
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                final emoji = getCategoryEmoji(category);
                final imageUrl = getCategoryImageUrl?.call(category);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: 'Category $category',
                    child: Tooltip(
                      message: category,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onCategorySelected(category);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: isSelected
                              ? _buildActiveNotchItem(emoji, imageUrl, category, screenBgColor, isDark)
                              : _buildInactiveItem(emoji, imageUrl, category),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildActiveNotchItem(
    String emoji,
    String? imageUrl,
    String category,
    Color screenBgColor,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ring Accent with curved elevation
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: screenBgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.onYellow,
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.maroonDeep.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipOval(
                    child: NetworkImageView(
                      imageUrl: imageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      fallbackEmoji: emoji,
                    ),
                  )
                : Text(
                    emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        // 11px Category Label under active icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onYellow,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildInactiveItem(String emoji, String? imageUrl, String category) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.onYellow.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipOval(
                    child: NetworkImageView(
                      imageUrl: imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      fallbackEmoji: emoji,
                    ),
                  )
                : Text(
                    emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
          ),
        ),
        const SizedBox(height: 3),
        // 11px Category Label under inactive icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            category,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onYellow.withValues(alpha: 0.82),
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
