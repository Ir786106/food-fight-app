import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../models/category_model.dart';
import 'rail_notch_painter.dart';

class CategoryRail extends StatefulWidget {
  final List<CategoryModel> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  const CategoryRail({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onMenuTap,
    required this.onSearchTap,
    required this.onFilterTap,
  });

  @override
  State<CategoryRail> createState() => _CategoryRailState();
}

class _CategoryRailState extends State<CategoryRail> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  double? _targetNotchY;
  double? _currentNotchY;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateNotchPosition);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateNotchPosition());
  }

  @override
  void didUpdateWidget(covariant CategoryRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory ||
        oldWidget.categories != widget.categories) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateNotchPosition());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateNotchPosition);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateNotchPosition() {
    final key = _itemKeys[widget.selectedCategory];
    if (key == null || key.currentContext == null) return;

    final box = key.currentContext!.findRenderObject() as RenderBox?;
    final railBox = context.findRenderObject() as RenderBox?;
    if (box != null && railBox != null && box.hasSize && railBox.hasSize) {
      final itemLocalOffset = box.localToGlobal(Offset.zero, ancestor: railBox);
      final itemCenterY = itemLocalOffset.dy + (box.size.height / 2);
      if (itemCenterY != _targetNotchY) {
        setState(() {
          _targetNotchY = itemCenterY;
        });
      }
    }
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('burger')) return Icons.lunch_dining_rounded;
    if (lower.contains('pizza')) return Icons.local_pizza_rounded;
    if (lower.contains('shawarma')) return Icons.kebab_dining_rounded;
    if (lower.contains('fries')) return Icons.fastfood_rounded;
    if (lower.contains('sandwich')) return Icons.bakery_dining_rounded;
    if (lower.contains('drink') || lower.contains('beverage')) return Icons.local_drink_rounded;
    if (lower.contains('deal') || lower.contains('offer')) return Icons.local_offer_rounded;
    if (lower.contains('bbq') || lower.contains('barbecue')) return Icons.outdoor_grill_rounded;
    if (lower.contains('family') || lower.contains('package')) return Icons.dinner_dining_rounded;
    if (lower == 'all') return Icons.grid_view_rounded;
    return Icons.restaurant_menu_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final railWidth = screenWidth < 360 ? 64.0 : 74.0;
    final buttonSize = screenWidth < 360 ? 48.0 : 54.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final railColor = isDark ? AppColors.darkSurfaceElevated : AppColors.brandYellow;
    final contentBgColor = isDark ? AppColors.darkBackground : AppColors.background;

    // List of items including "All"
    final allCategoryNames = ['All', ...widget.categories.map((c) => c.name)];

    return SizedBox(
      width: railWidth,
      child: Stack(
        children: [
          // Background with animated smooth notch on the right edge
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: _currentNotchY ?? _targetNotchY ?? 150.0,
                end: _targetNotchY ?? 150.0,
              ),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              builder: (context, notchY, child) {
                _currentNotchY = notchY;
                return RepaintBoundary(
                  child: CustomPaint(
                    painter: RailNotchPainter(
                      railColor: railColor,
                      contentBgColor: contentBgColor,
                      notchCenterY: _targetNotchY != null ? notchY : null,
                      notchRadius: buttonSize / 2 + 6,
                      notchDepth: 12.0,
                    ),
                  ),
                );
              },
            ),
          ),

          // Foreground vertical content
          SafeArea(
            bottom: true,
            right: false,
            child: Column(
              children: [
                const SizedBox(height: 10),

                // 1. Menu Button (opens drawer/sheet)
                _buildActionIconButton(
                  icon: Icons.menu_rounded,
                  tooltip: 'Menu & Settings',
                  onTap: widget.onMenuTap,
                  isDark: isDark,
                  size: buttonSize,
                ),

                const SizedBox(height: 8),

                // 2. Search Button (opens search screen)
                _buildActionIconButton(
                  icon: Icons.search_rounded,
                  tooltip: 'Search Food',
                  onTap: widget.onSearchTap,
                  isDark: isDark,
                  size: buttonSize,
                ),

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.maroonDeep.withValues(alpha: 0.12),
                  indent: 10,
                  endIndent: 10,
                ),
                const SizedBox(height: 12),

                // 3. Middle Scrollable Category Buttons
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: allCategoryNames.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final catName = allCategoryNames[index];
                      final isSelected = widget.selectedCategory.toLowerCase() == catName.toLowerCase();
                      final key = _itemKeys.putIfAbsent(catName, () => GlobalKey());

                      return Center(
                        child: _buildCategoryButton(
                          key: key,
                          name: catName,
                          isSelected: isSelected,
                          isDark: isDark,
                          size: buttonSize,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.maroonDeep.withValues(alpha: 0.12),
                  indent: 10,
                  endIndent: 10,
                ),
                const SizedBox(height: 8),

                // 4. Bottom Filter Button
                _buildActionIconButton(
                  icon: Icons.tune_rounded,
                  tooltip: 'Filters',
                  onTap: widget.onFilterTap,
                  isDark: isDark,
                  size: buttonSize,
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
    required double size,
  }) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.yellowPressed.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.brandYellow : AppColors.brandMaroon,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required Key key,
    required String name,
    required bool isSelected,
    required bool isDark,
    required double size,
  }) {
    final icon = _getCategoryIcon(name);

    final bgColor = isSelected
        ? (isDark ? AppColors.brandYellow : Colors.white)
        : (isDark
            ? AppColors.darkSurface
            : AppColors.yellowPressed.withValues(alpha: 0.65));

    final iconColor = isSelected
        ? (isDark ? AppColors.maroonDeep : AppColors.brandMaroon)
        : (isDark ? AppColors.brandYellow : AppColors.brandMaroon);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$name category',
      child: Tooltip(
        message: name,
        child: GestureDetector(
          key: key,
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onCategorySelected(name);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: size * 0.38),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: iconColor,
                      height: 1.05,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
