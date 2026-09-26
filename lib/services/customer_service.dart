import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/user_model.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Customer Management Service for Admin Panel
class CustomerService {
  static final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection(FirestoreCollections.users);
  static final CollectionReference _ordersCollection =
      FirebaseFirestore.instance.collection(FirestoreCollections.orders);

  /// Watch all registered customers
  static Stream<List<UserModel>> watchCustomers({String? search, bool? isActive}) {
    Query query = _usersCollection.where('role', isEqualTo: 'customer');

    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive ? 1 : 0);
    }

    return query.snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return UserModel.fromJson(data);
      }).toList();

      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        list = list.where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.phone.toLowerCase().contains(q)).toList();
      }

      return list;
    });
  }

  /// Toggle customer active / blocked status
  static Future<void> toggleCustomerStatus(String userId, bool currentStatus) async {
    await _usersCollection.doc(userId).update({
      'isActive': currentStatus ? 0 : 1,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    AppLogger.info('Toggled customer status for $userId to ${!currentStatus}', tag: 'CustomerService');
  }

  /// Fetch stats for a specific customer (total orders, total spent)
  static Future<Map<String, dynamic>> getCustomerStats(String customerId) async {
    try {
      final snapshot = await _ordersCollection
          .where('customerId', isEqualTo: customerId)
          .get();

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
