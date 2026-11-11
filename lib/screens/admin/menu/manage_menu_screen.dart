import 'package:food_fight/services/menu_service.dart';
import 'package:food_fight/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/providers/menu_provider.dart';
import 'package:food_fight/providers/category_provider.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/widgets/admin/admin_scaffold.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/empty_state_view.dart';
import 'package:food_fight/widgets/common/network_image_view.dart';
import 'package:food_fight/widgets/common/error_view.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'add_edit_menu_item_screen.dart';
import 'reupload_missing_images_screen.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _lastBranchId;
  bool _updatingMenu = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final branchId = auth.currentUser?.branchId;
    if (_lastBranchId != branchId) {
      _lastBranchId = branchId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<MenuProvider>().watchMenuItems(branchId: branchId);
          context.read<CategoryProvider>().watchCategories(branchId: branchId);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _confirmDelete(MenuItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.getCardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to delete "${item.name}"? This action also removes its image from the configured storage provider.'),
        actions: [
          IconButton(tooltip: 'Menu issue reports', icon: const Icon(Icons.flag_outlined), onPressed: () => Navigator.pushNamed(context, '/admin/menu-reports')),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<MenuProvider>().deleteMenuItem(item.id, imageUrl: item.imageUrl);
              if (mounted && success) {
                AppSnackbar.showSnackBar(context,
                  SnackBar(content: Text('"${item.name}" deleted successfully')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateVisibleItems(List<MenuItemModel> items, bool active) async {
    final auth = context.read<AuthProvider>();
    final branchId = auth.currentUser?.branchId?.trim();
    if (_updatingMenu || (!auth.isSuperAdmin && (branchId == null || branchId.isEmpty))) return;
    final ids = items
        .where((item) => item.isActive != active &&
            (auth.isSuperAdmin || item.branchId == branchId))
        .map((item) => item.id)
        .toSet();
    if (ids.isEmpty || ids.length > 500) {
      AppSnackbar.showInfo(context, ids.isEmpty
          ? 'No visible items need this change.'
          : 'Narrow the filters to 500 items or fewer.');
      return;
    }
    setState(() => _updatingMenu = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(active ? 'Activate menu items?' : 'Hide menu items?'),
          content: Text('This updates ${ids.length} items in the filtered view.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Apply'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await MenuService.setItemsActive(ids, active: active);
      if (mounted) AppSnackbar.showSuccess(context, 'Menu items updated.');
    } catch (_) {
      if (mounted) AppSnackbar.showError(context, 'Could not update menu items.');
    } finally {
      if (mounted) setState(() => _updatingMenu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AdminTheme.getCardBg(context);
    final textDark = AdminTheme.getTextDark(context);
    final textMuted = AdminTheme.getTextMuted(context);

    final categoryProvider = context.watch<CategoryProvider>();
    final menuProvider = context.watch<MenuProvider>();

    final categories = categoryProvider.categories;
    final menuItems = menuProvider.filteredItems;

    return AdminScaffold(
      currentRoute: '/admin/menu',
      backgroundColor: AdminTheme.getBackground(context),
      appBar: AppBar(
        title: const Text('Manage Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<bool>(
            enabled: !_updatingMenu && menuItems.isNotEmpty,
            tooltip: 'Bulk menu actions',
            onSelected: (active) => _updateVisibleItems(menuItems, active),
            itemBuilder: (_) => const [
              PopupMenuItem(value: true, child: Text('Activate visible items')),
              PopupMenuItem(value: false, child: Text('Hide visible items')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.broken_image_rounded),
            tooltip: 'Re-upload Missing Images',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReuploadMissingImagesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Menu Item',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditMenuItemScreen()),
            ),
          ),
        ],
      ),
      body: ResponsiveContainer.content(
        maxWidth: 1200,
        child: Column(
          children: [
            // Search and Add Button Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => menuProvider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Search menu by name or description...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  menuProvider.setSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddEditMenuItemScreen()),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // Horizontal Category Selector Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All Categories'),
                      selected: menuProvider.selectedCategory == 'All',
                      selectedColor: AdminTheme.primaryBlue,
                      labelStyle: TextStyle(
                        color: menuProvider.selectedCategory == 'All' ? Colors.white : textDark,
                        fontWeight: menuProvider.selectedCategory == 'All' ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        if (selected) menuProvider.setCategory('All');
                      },
                    ),
                  ),
                  ...categories.map((cat) {
                    final isSelected = menuProvider.selectedCategory == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        selectedColor: AdminTheme.primaryBlue,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : textDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          if (selected) menuProvider.setCategory(cat.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Menu Items List / Grid
            Expanded(
              child: menuProvider.isLoading && menuProvider.menuItems.isEmpty
                  ? const LoadingIndicator(message: 'Loading menu items...')
                  : menuProvider.errorMessage != null && menuProvider.menuItems.isEmpty
                      ? ErrorView(
                          message: menuProvider.errorMessage!,
                          onRetry: () => menuProvider.fetchMenuItems(),
                        )
                      : menuItems.isEmpty
                          ? EmptyStateView(
                              icon: Icons.restaurant_menu_rounded,
                              title: menuProvider.menuItems.isEmpty ? 'Menu is Empty' : 'No Items Found',
                              description: menuProvider.menuItems.isEmpty
                                  ? 'Add menu items to start building this branch menu.'
                                  : 'Try changing category filter or search keywords.',
                              buttonText: menuProvider.menuItems.isEmpty
                                  ? 'Add Menu Item'
                                  : null,
                              onButtonPressed: menuProvider.menuItems.isEmpty
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const AddEditMenuItemScreen()),
                                      )
                                  : null,
                            )
                          : RefreshIndicator(
                              onRefresh: () => menuProvider.fetchMenuItems(),
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: menuItems.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = menuItems[index];

                                  return Material(
                                    color: cardBg,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: NetworkImageView(
                                              imageUrl: item.imageUrl,
                                              width: 70,
                                              height: 70,
                                              fallbackIcon: Icons.fastfood_rounded,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        item.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 15,
                                                          color: textDark,
                                                        ),
                                                      ),
                                                    ),
                                                    if (item.isPopular)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        margin: const EdgeInsets.only(left: 6),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.warning.withValues(alpha: 0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Text(
                                                          'POPULAR',
                                                          style: TextStyle(
                                                            fontSize: 9.5,
                                                            fontWeight: FontWeight.w800,
                                                            color: AppColors.warning,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.description,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: textMuted, fontSize: 12.5),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Rs. ${item.finalPrice.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w800,
                                                        color: AdminTheme.primaryBlue,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    if (item.discount > 0) ...[
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Rs. ${item.price.toStringAsFixed(0)}',
                                                        style: TextStyle(
                                                          decoration: TextDecoration.lineThrough,
                                                          color: textMuted,
                                                          fontSize: 11.5,
                                                        ),
                                                      ),
                                                    ],
                                                    if (item.hasVariants) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AdminTheme.primaryBlue.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          '${item.variants?.length ?? 0} Sizes',
                                                          style: const TextStyle(
                                                            color: AdminTheme.primaryBlue,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              Switch(
                                                value: item.isActive,
                                                activeThumbColor: AdminTheme.primaryBlue,
                                                onChanged: (val) => menuProvider.toggleActive(item.id, item.isActive),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: Icon(Icons.more_vert_rounded, color: textMuted, size: 20),
                                                onSelected: (val) {
                                                  if (val == 'edit') {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => AddEditMenuItemScreen(item: item),
                                                      ),
                                                    );
                                                  } else if (val == 'delete') {
                                                    _confirmDelete(item);
                                                  }
                                                },
                                                itemBuilder: (_) => [
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit_rounded, size: 18, color: AppColors.darkBrown),
                                                        SizedBox(width: 8),
                                                        Text('Edit Item'),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete_rounded, size: 18, color: AppColors.error),
                                                        SizedBox(width: 8),
                                                        Text('Delete', style: TextStyle(color: AppColors.error)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditMenuItemScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Menu Item'),
      ),
    );
  }
}
