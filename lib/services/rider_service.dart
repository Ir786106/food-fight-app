import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rider_model.dart';
import '../models/order_model.dart';
import '../core/utils/logger.dart';

class RiderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _ridersCol = _firestore.collection('riders');
  static final CollectionReference _ordersCol = _firestore.collection('orders');

  /// Stream all delivery riders (Admin / Super Admin)
  static Stream<List<RiderModel>> watchAllRiders() {
    return _ridersCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return RiderModel.fromJson(data);
      }).toList();
    });
  }

  /// Create a new rider account
  static Future<void> createRider(RiderModel rider) async {
    try {
      final docRef = rider.id.isNotEmpty ? _ridersCol.doc(rider.id) : _ridersCol.doc();
      final data = rider.toJson();
      data['id'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(data);

      // Also ensure user document reflects the 'rider' role
      if (rider.userId.isNotEmpty) {
        await _firestore.collection('users').doc(rider.userId).set({
          'role': 'rider',
          'name': rider.name,
          'phone': rider.phone,
          'isActive': rider.isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      AppLogger.info('Created rider account ${docRef.id}', tag: 'RiderService');
    } catch (e) {
      AppLogger.error('Failed to create rider: $e', tag: 'RiderService');
      rethrow;
    }
  }

  /// Update rider details
  static Future<void> updateRider(RiderModel rider) async {
    try {
      final data = rider.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _ridersCol.doc(rider.id).update(data);
      AppLogger.info('Updated rider ${rider.id}', tag: 'RiderService');
    } catch (e) {
      AppLogger.error('Failed to update rider: $e', tag: 'RiderService');
      rethrow;
    }
  }

  /// Toggle rider active/deactivated status
  static Future<void> setRiderActive(String riderId, bool isActive) async {
    try {
      await _ridersCol.doc(riderId).update({
        'isActive': isActive ? 1 : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Failed to update rider active status: $e', tag: 'RiderService');
      rethrow;
    }
  }

  /// Toggle rider online/offline status
  static Future<void> setRiderOnline(String riderId, bool isOnline) async {
    try {
      await _ridersCol.doc(riderId).update({
        'isOnline': isOnline ? 1 : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Failed to update rider online status: $e', tag: 'RiderService');
      rethrow;
    }
  }

  /// Assign rider to an active order
  static Future<void> assignRiderToOrder({
    required String orderId,
    required String riderId,
    required String riderName,
    String? riderPhone,
  }) async {
    try {
      await _ordersCol.doc(orderId).update({
        'riderId': riderId,
        'riderName': riderName,
        if (riderPhone != null && riderPhone.isNotEmpty) 'riderPhone': riderPhone,
        'status': OrderStatus.assigned.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record assignment in riderAssignments subcollection
      await _firestore.collection('riderAssignments').add({
        'orderId': orderId,
        'riderId': riderId,
        'assignedAt': FieldValue.serverTimestamp(),
        'status': 'assigned',
      });

      AppLogger.info('Assigned rider $riderId to order $orderId', tag: 'RiderService');
    } catch (e) {
      AppLogger.error('Failed to assign rider: $e', tag: 'RiderService');
      rethrow;
    }
  }

  /// Watch active deliveries assigned to a specific rider
  static Stream<List<OrderModel>> watchRiderDeliveries(String riderId) {
    return _ordersCol
        .where('riderId', isEqualTo: riderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return OrderModel.fromJson(data);
      }).toList();
    });
  }
}
