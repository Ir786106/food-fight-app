import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/services/app_image_storage_service.dart';

/// Menu Item Management Service (Firestore backed, Supabase image storage)
class MenuService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection(FirestoreCollections.menuItems);

  /// Stream of menu items with optional category filtering and search, plus branch scoping
  static Stream<List<MenuItemModel>> watchMenuItems({
    String? categoryId,
    bool activeOnly = false,
    String? branchId,
  }) {
    Query query = _collection;
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'All') {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots().map((snapshot) {
      var items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return MenuItemModel.fromJson(data);
      }).toList();

      if (branchId != null && branchId.isNotEmpty && branchId.toLowerCase() != 'all') {
        items = items.where((i) => i.branchId == null || i.branchId == branchId).toList();
      }

      if (activeOnly) {
        return items.where((i) => i.isActive).toList();
      }
      return items;
    });
  }

  /// Get menu items as a Future
  static Future<List<MenuItemModel>> getMenuItems({String? categoryId, String? branchId}) async {
    try {
      Query query = _collection;
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'All') {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      final snapshot = await query.get();
      var items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return MenuItemModel.fromJson(data);
      }).toList();

      if (items.isEmpty) {
        // Fallback for alternate collection name 'menu_items'
        Query altQuery = FirebaseFirestore.instance.collection('menu_items');
        if (categoryId != null && categoryId.isNotEmpty && categoryId != 'All') {
          altQuery = altQuery.where('categoryId', isEqualTo: categoryId);
        }
        final altSnapshot = await altQuery.get();
        if (altSnapshot.docs.isNotEmpty) {
          items = altSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return MenuItemModel.fromJson(data);
          }).toList();
        }
      }

      if (branchId != null && branchId.isNotEmpty && branchId.toLowerCase() != 'all') {
        items = items.where((i) => i.branchId == null || i.branchId == branchId).toList();
      }

      return items;
    } catch (e) {
      AppLogger.error('Error fetching menu items: $e', tag: 'MenuService');
      return [];
    }
  }

  /// Get single menu item by ID
  static Future<MenuItemModel?> getMenuItem(String id) async {
    try {
      var doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        // Fallback to alternate collection name
        doc = await FirebaseFirestore.instance.collection('menu_items').doc(id).get();
      }
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return MenuItemModel.fromJson(data);
    } catch (e) {
      AppLogger.error('Error fetching menu item $id: $e', tag: 'MenuService');
      return null;
    }
  }

  /// Create new menu item
  static Future<String> createMenuItem(MenuItemModel item) async {
    final docRef = _collection.doc();
    final data = item.toJson();
    data['id'] = docRef.id;
    await docRef.set(data);
    AppLogger.info('Created menu item: ${item.name} (${docRef.id})', tag: 'MenuService');
    return docRef.id;
  }

  /// Update existing menu item
  static Future<void> updateMenuItem(MenuItemModel item) async {
    await _collection.doc(item.id).update(item.toJson());
    AppLogger.info('Updated menu item: ${item.id}', tag: 'MenuService');
  }

  /// Delete menu item and delete its image from Supabase Storage
  static Future<void> deleteMenuItem(String id, {String? imageUrl}) async {
    await _collection.doc(id).delete();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        await AppImageStorageService().deleteImage(imageUrl);
      } catch (e) {
        AppLogger.error('Failed to remove image: $e', tag: 'MenuService');
      }
    }
    AppLogger.info('Deleted menu item: $id', tag: 'MenuService');
  }

  /// Apply one availability update atomically to the selected menu items.
  static Future<void> setItemsActive(Set<String> ids, {required bool active}) async {
    if (ids.isEmpty) return;
    if (ids.length > 500) throw ArgumentError.value(ids.length, 'ids', 'Too many items');
    final batch = FirebaseFirestore.instance.batch();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    for (final id in ids) {
      batch.update(_collection.doc(id), {'isActive': active ? 1 : 0, 'updatedAt': timestamp});
    }
    await batch.commit();
  }

  /// Update only image metadata, keeping current catalog fields intact.
  static Future<void> updateImages(Set<String> itemIds, String imageUrl) async {
    if (itemIds.isEmpty) return;
    if (itemIds.length > 500) {
      throw ArgumentError.value(itemIds.length, 'itemIds', 'Too many items');
    }
    final batch = FirebaseFirestore.instance.batch();
    final updatedAt = FieldValue.serverTimestamp();
    for (final id in itemIds) {
      batch.update(_collection.doc(id), {'imageUrl': imageUrl, 'updatedAt': updatedAt});
    }
    await batch.commit();
  }

  /// Toggle menu item active status
  static Future<void> toggleActive(String id, bool currentStatus) async {
    await _collection.doc(id).update({
      'isActive': currentStatus ? 0 : 1,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
