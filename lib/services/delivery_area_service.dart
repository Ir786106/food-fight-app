import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/delivery_area_model.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Delivery Area Service (Firestore backed)
class DeliveryAreaService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection(FirestoreCollections.deliveryAreas);

  /// Watch delivery areas
  static Stream<List<DeliveryAreaModel>> watchDeliveryAreas({
    bool activeOnly = false,
    String? branchId,
  }) {
    Query query = _collection.orderBy('name');

    return query.snapshots().map((snapshot) {
      var items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return DeliveryAreaModel.fromJson(data);
      }).toList();
      if (branchId != null && branchId.isNotEmpty) {
        items = items.where((a) => a.branchId == null || a.branchId == branchId).toList();
      }
      if (activeOnly) {
        return items.where((a) => a.isActive).toList();
      }
      return items;
    });
  }

  /// Get delivery areas list
  static Future<List<DeliveryAreaModel>> getDeliveryAreas({
    bool activeOnly = false,
    String? branchId,
  }) async {
    try {
      final snapshot = await _collection.orderBy('name').get();
      var items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return DeliveryAreaModel.fromJson(data);
      }).toList();
      if (branchId != null && branchId.isNotEmpty) {
        items = items.where((a) => a.branchId == null || a.branchId == branchId).toList();
      }
      if (activeOnly) {
        return items.where((a) => a.isActive).toList();
      }
      return items;
    } catch (e) {
      AppLogger.error('Error fetching delivery areas: $e', tag: 'DeliveryAreaService');
      return [];
    }
  }

  /// Create delivery area
  static Future<String> createDeliveryArea(DeliveryAreaModel area) async {
    final docRef = _collection.doc();
    final data = area.toJson();
    data['id'] = docRef.id;
    await docRef.set(data);
    AppLogger.info('Created delivery area: ${area.name}', tag: 'DeliveryAreaService');
    return docRef.id;
  }

  /// Update delivery area
  static Future<void> updateDeliveryArea(DeliveryAreaModel area) async {
    await _collection.doc(area.id).update(area.toJson());
    AppLogger.info('Updated delivery area: ${area.id}', tag: 'DeliveryAreaService');
  }

  /// Delete delivery area
  static Future<void> deleteDeliveryArea(String id) async {
    await _collection.doc(id).delete();
    AppLogger.info('Deleted delivery area: $id', tag: 'DeliveryAreaService');
  }

  /// Toggle active
  static Future<void> toggleActive(String id, bool currentStatus) async {
    await _collection.doc(id).update({
      'isActive': currentStatus ? 0 : 1,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
