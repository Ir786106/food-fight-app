import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';
import '../models/deal_model.dart';

class DealService {
  final FirebaseFirestore? _customFirestore;
  DealService({FirebaseFirestore? firestore}) : _customFirestore = firestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  final String _collection = 'deals';

  CollectionReference<Map<String, dynamic>> get _dealsRef =>
      _firestore.collection(_collection);

  /// Stream deals for a branch (or all branches for Super Admin)
  Stream<List<DealModel>> streamDeals({String? branchId, bool activeOnly = false}) {
    Query<Map<String, dynamic>> query = _dealsRef;

    if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
      // Allow deals specific to this branch or global deals (branchId is '' or 'all')
      query = query.where('branchId', whereIn: [branchId, '', 'all']);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return DealModel.fromJson(data);
      }).where((d) {
        if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
          final matches = d.branchId == null ||
              d.branchId!.isEmpty ||
              d.branchId == 'all' ||
              d.branchId == branchId;
          if (!matches) return false;
        }
        if (activeOnly) {
          return d.isValidNow;
        }
        return true;
      }).toList();

      return list;
    });
  }

  /// Fetch active deals once for customer view
  Future<List<DealModel>> getActiveDealsForBranch(String? branchId) async {
    try {
      Query<Map<String, dynamic>> query = _dealsRef.where('isActive', isEqualTo: true);

      if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
        query = query.where('branchId', whereIn: [branchId, '', 'all']);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return DealModel.fromJson(data);
          })
          .where((d) {
            if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
              final matches = d.branchId == null ||
                  d.branchId!.isEmpty ||
                  d.branchId == 'all' ||
                  d.branchId == branchId;
              if (!matches) return false;
            }
            return d.isValidNow;
          })
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get active deals: $e', tag: 'DealService');
      return [];
    }
  }

  /// Create a new deal
  Future<String> createDeal(DealModel deal) async {
    try {
      final docRef = deal.id.isNotEmpty ? _dealsRef.doc(deal.id) : _dealsRef.doc();
      final data = deal.copyWith(id: docRef.id).toJson();
      await docRef.set(data);
      AppLogger.info('Deal created: ${docRef.id}', tag: 'DealService');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creating deal: $e', tag: 'DealService');
      rethrow;
    }
  }

  /// Update an existing deal
  Future<void> updateDeal(DealModel deal) async {
    try {
      await _dealsRef.doc(deal.id).update(deal.toJson());
      AppLogger.info('Deal updated: ${deal.id}', tag: 'DealService');
    } catch (e) {
      AppLogger.error('Error updating deal: $e', tag: 'DealService');
      rethrow;
    }
  }

  /// Delete a deal
  Future<void> deleteDeal(String dealId) async {
    try {
      await _dealsRef.doc(dealId).delete();
      AppLogger.info('Deal deleted: $dealId', tag: 'DealService');
    } catch (e) {
      AppLogger.error('Error deleting deal: $e', tag: 'DealService');
      rethrow;
    }
  }

  /// Toggle deal activation status
  Future<void> toggleStatus(String dealId, bool isActive) async {
    try {
      await _dealsRef.doc(dealId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      AppLogger.info('Deal $dealId status updated to $isActive', tag: 'DealService');
    } catch (e) {
      AppLogger.error('Error toggling deal status: $e', tag: 'DealService');
      rethrow;
    }
  }
}
