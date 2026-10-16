import 'package:flutter/material.dart';
import 'package:food_fight/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_fight/models/category_model.dart';
import 'package:food_fight/providers/category_provider.dart';
import 'package:food_fight/providers/menu_provider.dart';
import 'package:food_fight/providers/auth_provider.dart';
import 'package:food_fight/services/app_image_storage_service.dart';
import 'package:food_fight/core/constants/image_storage.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/theme/admin_theme.dart';
import 'package:food_fight/widgets/admin/admin_drawer.dart';
import 'package:food_fight/widgets/common/loading_indicator.dart';
import 'package:food_fight/widgets/common/empty_state_view.dart';
import 'package:food_fight/widgets/common/network_image_view.dart';
import 'package:food_fight/widgets/common/error_view.dart';
import 'package:food_fight/widgets/common/responsive_layout.dart';
import 'package:food_fight/core/utils/validator_utils.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _lastBranchId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final branchId = auth.currentUser?.branchId;
    if (_lastBranchId != branchId) {
      _lastBranchId = branchId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
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

  void _openCategoryDialog({CategoryModel? category}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    final orderController = TextEditingController(text: (category?.order ?? 0).toString());
    String? imageUrl = category?.imageUrl;
    XFile? pickedImage;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: AdminTheme.getCardBg(dialogContext),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              category == null ? 'Add New Category' : 'Edit Category',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AdminTheme.getTextDark(dialogContext),
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Picker
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.grey.shade300,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: pickedImage != null
                                  ? const Center(
                                      child: Icon(Icons.check_circle, color: AppColors.success, size: 36),
                                    )
                                  : NetworkImageView(
                                      imageUrl: imageUrl,
                                      width: 100,
                                      height: 100,
                                      fallbackIcon: Icons.fastfood_rounded,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () async {
                                final img = await AppImageStorageService.pickImage();
                                if (img != null) {
                                  setDialogState(() => pickedImage = img);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  color: AdminTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: nameController,
                      validator: (val) => ValidatorUtils.validateRequired(val, fieldName: 'Category name'),
                      decoration: InputDecoration(
                        labelText: 'Category Name *',
                        hintText: 'e.g. Burgers, Pizza, Sides',
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Short summary for customers',
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: orderController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Display Order Priority',
                        hintText: '0, 1, 2...',
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        final provider = context.read<CategoryProvider>();
                        final currentBranchId = context.read<AuthProvider>().currentUser?.branchId;

                        setDialogState(() => isSaving = true);
                        try {
                          String? finalImageUrl = imageUrl;
                          if (pickedImage != null) {
                            final storage = AppImageStorageService();
                            finalImageUrl = await storage.uploadImage(
                              image: pickedImage!,
                              path: StoragePaths.categoryImagesPath,
                            );
                          }

                          final orderNum = int.tryParse(orderController.text.trim()) ?? 0;
                          final name = nameController.text.trim();
                          final desc = descController.text.trim();

                          if (category == null) {
                            await provider.createCategory(CategoryModel(
                              id: '',
                              name: name,
                              description: desc,
                              imageUrl: finalImageUrl,
                              order: orderNum,
                              isActive: true,
                              branchId: currentBranchId,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ));
                          } else {
                            await provider.updateCategory(CategoryModel(
                              id: category.id,
                              name: name,
                              description: desc,
                              imageUrl: finalImageUrl,
                              order: orderNum,
                              isActive: category.isActive,
                              branchId: category.branchId ?? currentBranchId,
                              createdAt: category.createdAt,
                              updatedAt: DateTime.now(),
                            ));
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e, stack) {
                          AppLogger.error('Category save error: $e\n$stack', tag: 'ManageCategories');
                          setDialogState(() => isSaving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('No connection. Please check your internet and try again.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(category == null ? 'Create' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.getCardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<CategoryProvider>().deleteCategory(category.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "${category.name}" deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AdminTheme.getCardBg(context);
    final textDark = AdminTheme.getTextDark(context);
    final textMuted = AdminTheme.getTextMuted(context);

    return Scaffold(
      backgroundColor: AdminTheme.getBackground(context),
      drawer: const AdminDrawer(currentRoute: '/admin/categories'),
      appBar: AppBar(
        title: const Text('Manage Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Category',
            onPressed: () => _openCategoryDialog(),
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const LoadingIndicator(message: 'Loading categories...');
          }

          if (provider.errorMessage != null && provider.categories.isEmpty) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.fetchCategories(),
            );
          }

          final query = _searchCtrl.text.trim().toLowerCase();
          final filteredCategories = provider.categories.where((c) {
            return query.isEmpty ||
                c.name.toLowerCase().contains(query) ||
                (c.description?.toLowerCase().contains(query) ?? false);
          }).toList();

          return ResponsiveContainer.content(
            maxWidth: 1200,
            child: Column(
              children: [
                // Top Search Bar (clean and full-width, no duplicate add button crowding)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
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

                // Category List
                Expanded(
                  child: filteredCategories.isEmpty
                      ? EmptyStateView(
                          icon: Icons.category_rounded,
                          title: provider.categories.isEmpty ? 'No Categories Found' : 'No Matching Categories',
                          description: provider.categories.isEmpty
                              ? 'Create food categories to organize your menu items.'
                              : 'Try searching with a different term.',
                          buttonText: provider.categories.isEmpty ? 'Create Category' : null,
                          onButtonPressed: provider.categories.isEmpty ? () => _openCategoryDialog() : null,
                        )
                      : RefreshIndicator(
                          onRefresh: () => provider.fetchCategories(),
                          child: Consumer<MenuProvider>(
                            builder: (context, menuProv, _) {
                              return ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                                itemCount: filteredCategories.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final cat = filteredCategories[index];
                                  final itemCount = menuProv.menuItems.where((i) =>
                                    i.categoryId == cat.id
                                  ).length;

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
                                            borderRadius: BorderRadius.circular(12),
                                            child: NetworkImageView(
                                              imageUrl: cat.imageUrl,
                                              width: 54,
                                              height: 54,
                                              fit: BoxFit.cover,
                                              fallbackIcon: Icons.restaurant_rounded,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  cat.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: textDark,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AdminTheme.primaryBlue.withValues(alpha: 0.08),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        'Priority: ${cat.order}',
                                                        style: const TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.w600,
                                                          color: AdminTheme.primaryBlue,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primaryYellow.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        '$itemCount items',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.w600,
                                                          color: isDark ? AppColors.primaryYellow : AppColors.brandMaroon,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (cat.description?.isNotEmpty == true) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    cat.description!,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(color: textMuted, fontSize: 12),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Transform.scale(
                                                scale: 0.85,
                                                child: Switch(
                                                  value: cat.isActive,
                                                  activeThumbColor: AdminTheme.primaryBlue,
                                                  onChanged: (val) => provider.toggleActive(cat.id, cat.isActive),
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit_rounded, size: 18),
                                                    color: AdminTheme.primaryBlue,
                                                    visualDensity: VisualDensity.compact,
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                    tooltip: 'Edit Category',
                                                    onPressed: () => _openCategoryDialog(category: cat),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                                    color: AppColors.error,
                                                    visualDensity: VisualDensity.compact,
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                    tooltip: 'Delete Category',
                                                    onPressed: () => _confirmDelete(cat),
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
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: () => _openCategoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }
}
