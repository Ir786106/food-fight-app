import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/menu_item_model.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/services/supabase/supabase_image_storage_service.dart';

/// Menu Item Management Service (Firestore backed, Supabase image storage)
class MenuService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection(FirestoreCollections.menuItems);

  /// Stream of menu items with optional category filtering and search
  static Stream<List<MenuItemModel>> watchMenuItems({
    String? categoryId,
    bool activeOnly = false,
  }) {
    Query query = _collection;
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: 1);
    }
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'All') {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return MenuItemModel.fromJson(data);
      }).toList();
    });
  }

  /// Get menu items as a Future
  static Future<List<MenuItemModel>> getMenuItems({String? categoryId}) async {
    try {
      Query query = _collection;
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'All') {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return MenuItemModel.fromJson(data);
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching menu items: $e', tag: 'MenuService');
      return [];
    }
  }

  /// Get single menu item by ID
  static Future<MenuItemModel?> getMenuItem(String id) async {
    try {
      final doc = await _collection.doc(id).get();
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
        await SupabaseImageStorageService().deleteImage(imageUrl);
      } catch (e) {
        AppLogger.error('Failed to remove image from Supabase: $e', tag: 'MenuService');
      }
    }
    AppLogger.info('Deleted menu item: $id', tag: 'MenuService');
  }

  /// Toggle menu item active status
  static Future<void> toggleActive(String id, bool currentStatus) async {
    await _collection.doc(id).update({
      'isActive': currentStatus ? 0 : 1,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
