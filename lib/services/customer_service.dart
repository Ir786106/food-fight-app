import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Customer Management Service for Admin Panel
class CustomerService {
  static final CollectionReference _ordersCollection =
      FirebaseFirestore.instance.collection(FirestoreCollections.orders);

  static HttpsCallable get _directory =>
      FirebaseFunctions.instance.httpsCallable('manageBranchCustomers');

  static Future<List<UserModel>> getCustomers() async {
    final result = await _directory.call<Map<String, dynamic>>({'action': 'list'});
    final customers = result.data['customers'] as List;
    return customers
        .map((data) => UserModel.fromJson(Map<String, dynamic>.from(data as Map)))
        .toList();
  }

  /// Toggle customer active / blocked status
  static Future<void> toggleCustomerStatus(String userId, bool currentStatus) async {
    await _directory.call({
      'action': 'setStatus',
      'customerId': userId,
      'active': !currentStatus,
    });
    AppLogger.info('Toggled customer status for $userId to ${!currentStatus}', tag: 'CustomerService');
  }

  /// Fetch stats for a specific customer (total orders, total spent)
  static Future<Map<String, dynamic>> getCustomerStats(String customerId, {String? branchId}) async {
    try {
      Query q = _ordersCollection.where('customerId', isEqualTo: customerId);
      if (branchId != null && branchId.isNotEmpty) {
        q = q.where('branchId', isEqualTo: branchId);
      }
      final snapshot = await q.get();

      int totalOrders = snapshot.docs.length;
      double totalSpent = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['status'] ?? '').toString().toLowerCase();
        if (status != 'cancelled') {
          totalSpent += (data['total'] ?? 0).toDouble();
        }
      }

      return {
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      AppLogger.error('Error fetching customer stats: $e', tag: 'CustomerService');
      return {
        'totalOrders': 0,
        'totalSpent': 0.0,
      };
    }
  }
}
