import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/category_model.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Category Management Service (Firestore backed)
class CategoryService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection(FirestoreCollections.categories);

  /// Stream of all active/all categories
  static Stream<List<CategoryModel>> watchCategories({
    bool activeOnly = false,
    String? branchId,
  }) {
    Query query = _collection.orderBy('order');
    return query.snapshots().map((snapshot) {
      var items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CategoryModel.fromJson(data);
      }).toList();
      if (branchId != null && branchId.isNotEmpty) {
        items = items.where((c) => c.branchId == null || c.branchId == branchId).toList();
      }
      if (activeOnly) {
        return items.where((c) => c.isActive).toList();
      }
      return items;
    });
  }

  /// Get list of categories
  static Future<List<CategoryModel>> getCategories({String? branchId}) async {
    try {
      final snapshot = await _collection.orderBy('order').get();
      var items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CategoryModel.fromJson(data);
      }).toList();
      if (branchId != null && branchId.isNotEmpty) {
        items = items.where((c) => c.branchId == null || c.branchId == branchId).toList();
      }
      return items;
    } catch (e) {
      AppLogger.error('Error fetching categories: $e', tag: 'CategoryService');
      return [];
    }
  }

  /// Create new category
  static Future<String> createCategory(CategoryModel category) async {
    final docRef = _collection.doc();
    final data = category.toJson();
    data['id'] = docRef.id;
    await docRef.set(data);
    AppLogger.info('Created category: ${category.name} (${docRef.id})', tag: 'CategoryService');
    return docRef.id;
  }

  /// Update existing category
  static Future<void> updateCategory(CategoryModel category) async {
    await _collection.doc(category.id).update(category.toJson());
    AppLogger.info('Updated category: ${category.id}', tag: 'CategoryService');
  }

  /// Delete category
  static Future<void> deleteCategory(String categoryId) async {
    await _collection.doc(categoryId).delete();
    AppLogger.info('Deleted category: $categoryId', tag: 'CategoryService');
  }

  /// Toggle category active status
  static Future<void> toggleActive(String categoryId, bool currentStatus) async {
    await _collection.doc(categoryId).update({
      'isActive': currentStatus ? 0 : 1,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
