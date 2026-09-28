import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/branch_model.dart';
import '../core/constants/firestore_collections.dart';
import '../core/utils/logger.dart';

class BranchService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection(FirestoreCollections.branches);

  /// Watch all branches in real-time
  static Stream<List<BranchModel>> watchBranches() {
    return _collection.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return BranchModel.fromJson(data);
      }).toList();
      list.sort((a, b) => b.revenue.compareTo(a.revenue));
      return list;
    });
  }

  /// Get list of branches once
  static Future<List<BranchModel>> getBranches() async {
    try {
      final snapshot = await _collection.get();
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return BranchModel.fromJson(data);
      }).toList();
      list.sort((a, b) => b.revenue.compareTo(a.revenue));
      return list;
    } catch (e) {
      AppLogger.error('Failed to get branches: $e', tag: 'BranchService');
      return [];
    }
  }

  /// Get single branch by ID
  static Future<BranchModel?> getBranch(String branchId) async {
    try {
      final doc = await _collection.doc(branchId).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return BranchModel.fromJson(data);
    } catch (e) {
      AppLogger.error('Failed to get branch $branchId: $e', tag: 'BranchService');
      return null;
    }
  }

  /// Create new branch doc in Firestore
  static Future<String> createBranch(BranchModel branch) async {
    final docRef = branch.id.isNotEmpty ? _collection.doc(branch.id) : _collection.doc();
    final data = branch.toJson();
    data['id'] = docRef.id;
    await docRef.set(data);
    AppLogger.info('Created branch: ${branch.name} (${docRef.id})', tag: 'BranchService');
    return docRef.id;
  }

  /// Update existing branch
  static Future<void> updateBranch(BranchModel branch) async {
    final data = branch.toJson();
    data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await _collection.doc(branch.id).set(data, SetOptions(merge: true));
    AppLogger.info('Updated branch: ${branch.name} (${branch.id})', tag: 'BranchService');
  }

  /// Increment revenue and order count for a branch
  static Future<void> recordOrderFinancials(String branchId, double orderTotal) async {
    if (branchId.isEmpty) return;
    try {
      await _collection.doc(branchId).update({
        'revenue': FieldValue.increment(orderTotal),
        'orderCount': FieldValue.increment(1),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      AppLogger.warn('Could not increment branch financials for $branchId: $e', tag: 'BranchService');
    }
  }

  /// Seed initial 5 branches if collection is empty
  static Future<void> seedInitialBranchesIfEmpty() async {
    try {
      final snapshot = await _collection.limit(1).get();
      if (snapshot.docs.isNotEmpty) return; // already populated

      final defaultBranches = [
        BranchModel(
          id: 'branch-dha-lhr',
          name: 'Food Fight – DHA Phase 5 (Lahore)',
          address: 'Plaza 42, Sector CCA, Phase 5 DHA, Lahore',
          city: 'Lahore',
          phone: '042-35789001',
          status: 'active',
          revenue: 1450000.0,
          orderCount: 1240,
          expenses: 850000.0,
          rating: 4.9,
          openingHours: '11:00 AM – 03:00 AM',
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          updatedAt: DateTime.now(),
        ),
        BranchModel(
          id: 'branch-gulberg-lhr',
          name: 'Food Fight – Gulberg III (Lahore)',
          address: 'MM Alam Road, Near Mini Market, Gulberg III, Lahore',
          city: 'Lahore',
          phone: '042-35789002',
          status: 'active',
          revenue: 1980000.0,
          orderCount: 1650,
          expenses: 1100000.0,
          rating: 4.8,
          openingHours: '11:00 AM – 02:00 AM',
          createdAt: DateTime.now().subtract(const Duration(days: 120)),
          updatedAt: DateTime.now(),
        ),
        BranchModel(
          id: 'branch-f7-isb',
          name: 'Food Fight – F-7 Markaz (Islamabad)',
          address: 'Shop 12, Jinnah Super Market, F-7 Markaz, Islamabad',
          city: 'Islamabad',
          phone: '051-2654321',
          status: 'active',
          revenue: 1220000.0,
          orderCount: 980,
          expenses: 780000.0,
          rating: 4.9,
          openingHours: '11:30 AM – 02:30 AM',
          createdAt: DateTime.now().subtract(const Duration(days: 75)),
          updatedAt: DateTime.now(),
        ),
        BranchModel(
          id: 'branch-bahria-rwp',
          name: 'Food Fight – Bahria Town (Phase 7)',
          address: 'Civic Center, Commercial Area Phase 7, Bahria Town, Rawalpindi',
          city: 'Rawalpindi',
          phone: '051-5178900',
          status: 'active',
          revenue: 890000.0,
          orderCount: 710,
          expenses: 620000.0,
          rating: 4.7,
          openingHours: '12:00 PM – 02:00 AM',
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          updatedAt: DateTime.now(),
        ),
        BranchModel(
          id: 'branch-clifton-khi',
          name: 'Food Fight – Clifton Block 4 (Karachi)',
          address: 'Plot 18, Block 4, Clifton Marine Drive, Karachi',
          city: 'Karachi',
          phone: '021-35876543',
          status: 'active',
          revenue: 1620000.0,
          orderCount: 1390,
          expenses: 990000.0,
          rating: 4.8,
          openingHours: '12:00 PM – 04:00 AM',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          updatedAt: DateTime.now(),
        ),
      ];

      for (var b in defaultBranches) {
        await _collection.doc(b.id).set(b.toJson());
      }
      AppLogger.info('Successfully seeded 5 initial branches', tag: 'BranchService');
    } catch (e) {
      AppLogger.warn('Error during branch seeding: $e', tag: 'BranchService');
    }
  }
}
