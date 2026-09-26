import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_fight/models/category_model.dart';
import 'package:food_fight/providers/category_provider.dart';
import 'package:food_fight/services/supabase/supabase_image_storage_service.dart';
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
                                      child: Icon(Icons.check_circle, color: Colors.green, size: 36),
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
                                final img = await SupabaseImageStorageService.pickImage();
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

                        setDialogState(() => isSaving = true);
                        try {
                          String? finalImageUrl = imageUrl;
                          if (pickedImage != null) {
                            final storage = SupabaseImageStorageService();
                            finalImageUrl = await storage.uploadImage(
                              image: pickedImage!,
                              path: 'categories/',
                            );
                          }

                          final orderNum = int.tryParse(orderController.text.trim()) ?? 0;
                          final name = nameController.text.trim();
                          final desc = descController.text.trim();

                          final provider = context.read<CategoryProvider>();

                          if (category == null) {
                            await provider.createCategory(CategoryModel(
                              id: '',
                              name: name,
                              description: desc,
                              imageUrl: finalImageUrl,
                              order: orderNum,
                              isActive: true,
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
                              createdAt: category.createdAt,
                              updatedAt: DateTime.now(),
                            ));
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
              backgroundColor: Colors.red,
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
                // Top Search & Header Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
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
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _openCategoryDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
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
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredCategories.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final cat = filteredCategories[index];

                              return Material(
                                color: cardBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: NetworkImageView(
                                      imageUrl: cat.imageUrl,
                                      width: 50,
                                      height: 50,
                                      fallbackIcon: Icons.restaurant_rounded,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          cat.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: textDark,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AdminTheme.primaryBlue.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Order: ${cat.order}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AdminTheme.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    cat.description?.isNotEmpty == true
                                        ? cat.description!
                                        : 'No description provided',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: textMuted, fontSize: 12.5),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: cat.isActive,
                                        activeThumbColor: AdminTheme.primaryBlue,
                                        onChanged: (val) => provider.toggleActive(cat.id, cat.isActive),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert_rounded, color: textMuted),
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            _openCategoryDialog(category: cat);
                                          } else if (val == 'delete') {
                                            _confirmDelete(cat);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
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
