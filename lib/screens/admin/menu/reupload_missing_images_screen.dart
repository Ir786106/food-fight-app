import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/constants/image_storage.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/utils/logger.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/menu_provider.dart';
import '../../../services/app_image_storage_service.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../widgets/common/network_image_view.dart';

enum ImageIssueType { all, missingOnly, unreachableOnly, validOnly }

/// One-time admin recovery and auditing tool:
/// "Re-upload missing product images"
/// Lists all menu items with empty or unreachable imageUrl,
/// and allows the admin to easily upload fresh photos or batch-assign branded assets.
class ReuploadMissingImagesScreen extends StatefulWidget {
  const ReuploadMissingImagesScreen({super.key});

  @override
  State<ReuploadMissingImagesScreen> createState() => _ReuploadMissingImagesScreenState();
}

class _ReuploadMissingImagesScreenState extends State<ReuploadMissingImagesScreen> {
  ImageIssueType _filter = ImageIssueType.all;
  final Map<String, bool> _uploadingItemIds = {};
  final Map<String, double> _uploadProgress = {};
  bool _isBatchProcessing = false;

  bool _isItemMissing(MenuItemModel item) {
    return item.imageUrl == null || item.imageUrl!.trim().isEmpty;
  }

  bool _isItemUnreachable(MenuItemModel item) {
    if (_isItemMissing(item)) return false;
    final url = item.imageUrl!.toLowerCase().trim();
    return url.contains('supabase.co');
  }

  bool _isItemValid(MenuItemModel item) {
    return !_isItemMissing(item) && !_isItemUnreachable(item);
  }

  Future<void> _uploadForItem(MenuItemModel item) async {
    final img = await AppImageStorageService.pickImage();
    if (img == null) return;

    setState(() {
      _uploadingItemIds[item.id] = true;
      _uploadProgress[item.id] = 0.05;
    });

    try {
      final storage = AppImageStorageService();
      final newUrl = await storage.uploadImage(
        image: img,
        path: StoragePaths.productImagesPath,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress[item.id] = p);
        },
      );

      // Persist directly into Firestore
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.menuItems)
          .doc(item.id)
          .update({
        'imageUrl': newUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        context.read<MenuProvider>().watchMenuItems();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully updated image for "${item.name}"!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.error('Failed to upload image for ${item.id}: $e\n$stack', tag: 'ReuploadTool');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No connection. Please check your internet and try again.'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _uploadForItem(item),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingItemIds.remove(item.id);
          _uploadProgress.remove(item.id);
        });
      }
    }
  }

  Future<void> _assignDefaultBrandedLogo(MenuItemModel item) async {
    const brandedAsset = 'assets/images/branding/food_fight_logo_icon.png';
    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.menuItems)
          .doc(item.id)
          .update({
        'imageUrl': brandedAsset,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Set branded default icon for "${item.name}"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error assigning logo: $e', tag: 'ReuploadTool');
    }
  }

  Future<void> _batchFixAllMissing(List<MenuItemModel> missingItems) async {
    if (missingItems.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batch Assign Branded Emblem?'),
        content: Text(
          'This will set a high-resolution branded Food Fight emblem for all ${missingItems.length} items without an image so no item shows empty in the customer panel.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batch Apply'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isBatchProcessing = true);
    int count = 0;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final item in missingItems) {
        final docRef = FirebaseFirestore.instance.collection(FirestoreCollections.menuItems).doc(item.id);
        batch.update(docRef, {
          'imageUrl': 'assets/images/branding/food_fight_logo_icon.png',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        count++;
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated $count menu items with branded emblem!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Batch update failed: $e', tag: 'ReuploadTool');
    } finally {
      if (mounted) setState(() => _isBatchProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final allItems = menuProvider.items;

    final missingCount = allItems.where(_isItemMissing).length;
    final unreachableCount = allItems.where(_isItemUnreachable).length;
    final validCount = allItems.where(_isItemValid).length;

    List<MenuItemModel> displayedItems;
    switch (_filter) {
      case ImageIssueType.missingOnly:
        displayedItems = allItems.where(_isItemMissing).toList();
        break;
      case ImageIssueType.unreachableOnly:
        displayedItems = allItems.where(_isItemUnreachable).toList();
        break;
      case ImageIssueType.validOnly:
        displayedItems = allItems.where(_isItemValid).toList();
        break;
      case ImageIssueType.all:
        displayedItems = allItems;
        break;
    }

    return Scaffold(
      backgroundColor: AdminTheme.getBackground(context),
      appBar: AppBar(
        title: const Text('Product Images Audit & Fix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AdminTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (missingCount > 0)
            IconButton(
              icon: _isBatchProcessing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_fix_high_rounded),
              tooltip: 'Batch Assign Branded Emblem to Missing',
              onPressed: _isBatchProcessing ? null : () => _batchFixAllMissing(allItems.where(_isItemMissing).toList()),
            ),
        ],
      ),
      body: Column(
        children: [
          // Diagnostic Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: AdminTheme.getCardBg(context),
            child: Row(
              children: [
                _buildMetricCard(context, 'Total', allItems.length.toString(), Colors.blueGrey),
                const SizedBox(width: 8),
                _buildMetricCard(context, 'Missing', missingCount.toString(), AppColors.warning),
                const SizedBox(width: 8),
                _buildMetricCard(context, 'Supabase (Old)', unreachableCount.toString(), AppColors.error),
                const SizedBox(width: 8),
                _buildMetricCard(context, 'Valid', validCount.toString(), AppColors.success),
              ],
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All (${allItems.length})', ImageIssueType.all),
                  const SizedBox(width: 8),
                  _buildFilterChip('Missing Only ($missingCount)', ImageIssueType.missingOnly),
                  const SizedBox(width: 8),
                  _buildFilterChip('Supabase Only ($unreachableCount)', ImageIssueType.unreachableOnly),
                  const SizedBox(width: 8),
                  _buildFilterChip('Valid Only ($validCount)', ImageIssueType.validOnly),
                ],
              ),
            ),
          ),

          // Items list
          Expanded(
            child: menuProvider.isLoading
                ? const Center(child: LoadingIndicator())
                : displayedItems.isEmpty
                    ? Center(
                        child: Text(
                          'No items matching filter',
                          style: TextStyle(color: AdminTheme.getTextMuted(context)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final item = displayedItems[i];
                          final isMissing = _isItemMissing(item);
                          final isUnreachable = _isItemUnreachable(item);
                          final isUploading = _uploadingItemIds[item.id] == true;
                          final progress = _uploadProgress[item.id] ?? 0.0;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AdminTheme.getCardBg(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isMissing
                                    ? AppColors.warning.withValues(alpha: 0.5)
                                    : isUnreachable
                                        ? AppColors.error.withValues(alpha: 0.5)
                                        : Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Thumbnail Preview
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: isUploading
                                        ? Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              CircularProgressIndicator(
                                                value: progress > 0 ? progress : null,
                                                color: AdminTheme.primaryBlue,
                                              ),
                                              Center(
                                                child: Text(
                                                  '${(progress * 100).toInt()}%',
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          )
                                        : NetworkImageView(
                                            imageUrl: item.imageUrl,
                                            width: 56,
                                            height: 56,
                                            borderRadius: 8,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Item Info & Status
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AdminTheme.getTextDark(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isMissing
                                                  ? AppColors.warning.withValues(alpha: 0.15)
                                                  : isUnreachable
                                                      ? AppColors.error.withValues(alpha: 0.15)
                                                      : AppColors.success.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isMissing
                                                  ? 'No Image'
                                                  : isUnreachable
                                                      ? 'Old Supabase Host'
                                                      : 'Valid URL',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isMissing
                                                    ? AppColors.warning
                                                    : isUnreachable
                                                        ? AppColors.error
                                                        : AppColors.success,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Rs. ${item.price.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AdminTheme.getTextMuted(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Action Buttons
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.image_outlined, size: 20),
                                      tooltip: 'Assign Default Logo',
                                      onPressed: isUploading ? null : () => _assignDefaultBrandedLogo(item),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AdminTheme.primaryBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                                      label: Text(isUploading ? 'Uploading...' : 'Upload'),
                                      onPressed: isUploading ? null : () => _uploadForItem(item),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 10, color: AdminTheme.getTextMuted(context)), maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, ImageIssueType type) {
    final selected = _filter == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = type),
      selectedColor: AdminTheme.primaryBlue,
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
