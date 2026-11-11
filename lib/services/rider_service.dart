import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/rider_model.dart';
import '../core/constants/firestore_collections.dart';
import '../core/utils/logger.dart';

class RiderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference<Map<String, dynamic>> _ridersCol =
      _firestore.collection(FirestoreCollections.riders);
  static final CollectionReference<Map<String, dynamic>> _ordersCol =
      _firestore.collection(FirestoreCollections.orders);

  /// Create a new rider account in Firebase Auth and Firestore with email & password.
  /// Uses a secondary FirebaseApp instance so the currently logged-in Admin is NEVER logged out.
  static Future<String> createRiderWithAuth({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? vehicleType,
    String? vehicleNumber,
  }) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('provisionTeamMember')
        .call({
      'role': 'rider',
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'linkExisting': password.isEmpty,
    });
    return result.data['userId'] as String;
  }

  /// Stream all delivery riders (Admin / Super Admin)
  static Stream<List<RiderModel>> watchAllRiders({String? branchId}) {
    final query = branchId == null ? _ridersCol : _ridersCol.where('branchId', isEqualTo: branchId);
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RiderModel.fromJson(data);
      }).toList();
    });
  }

  static Stream<RiderModel?> watchRider(String riderId) =>
      _ridersCol.doc(riderId).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) return null;
        return RiderModel.fromJson({...data, 'id': doc.id});
      });

  /// Create a new rider account
  static Future<void> createRider(RiderModel rider) async {
    try {
      final docRef =
          rider.id.isNotEmpty ? _ridersCol.doc(rider.id) : _ridersCol.doc();
      final data = rider.toJson();
      data['id'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(data);

      // Also ensure user document reflects the 'delivery_rider' role
      if (rider.userId.isNotEmpty) {
        await _firestore
            .collection(FirestoreCollections.users)
            .doc(rider.userId)
            .set({
          'role': 'delivery_rider',
          'name': rider.name,
          'phone': rider.phone,
          'isActive': rider.isActive ? 1 : 0,
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
      AppLogger.error('Failed to update rider active status: $e',
          tag: 'RiderService');
      rethrow;
    }
  }

  /// Toggle rider online/offline status
  static Future<void> setRiderOnline(String riderId, bool isOnline) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final riderRef = _ridersCol.doc(riderId);
        final rider = await transaction.get(riderRef);
        if (!rider.exists)
          throw StateError(
              'Rider profile not found. Contact your administrator.');
        final active = rider.data()?['isActive'];
        if (isOnline && active != true && active != 1) {
          throw StateError(
              'Your rider account is inactive. Contact your administrator.');
        }
        transaction.update(riderRef, {
          'isOnline': isOnline ? 1 : 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      AppLogger.error('Failed to update rider online status: $e',
          tag: 'RiderService');
      rethrow;
    }
  }

  static Future<void> assignRiderToOrder({
    required String orderId,
    required String riderId,
    required String riderName,
    String? riderPhone,
    String? expectedRiderId,
  }) async {
    await FirebaseFunctions.instance.httpsCallable('mutateOrder').call({
      'action': 'assign',
      'orderId': orderId,
      'riderId': riderId,
      'expectedRiderId': expectedRiderId,
    });
  }

  static Future<void> unassignRiderFromOrder({
    required String orderId,
    required String expectedRiderId,
  }) async {
    await FirebaseFunctions.instance.httpsCallable('mutateOrder').call({
      'action': 'unassign',
      'orderId': orderId,
      'expectedRiderId': expectedRiderId,
    });
  }

  static Future<void> acceptDelivery(String orderId) async {
    await FirebaseFunctions.instance.httpsCallable('mutateOrder').call({
      'action': 'accept',
      'orderId': orderId,
    });
  }

  static Future<void> declineDelivery(String orderId) async {
    await FirebaseFunctions.instance.httpsCallable('mutateOrder').call({
      'action': 'decline',
      'orderId': orderId,
    });
  }

  static Query<Map<String, dynamic>> _riderOrdersQuery(String riderId) =>
      _ordersCol
          .where('riderId', isEqualTo: riderId)
          .orderBy('createdAt', descending: true);

  static Future<void> refreshRiderOrders(String riderId) async {
    // The live listener already maintains the history. Refresh the recent window
    // without repeating an unbounded server read on every pull gesture.
    await _riderOrdersQuery(riderId).limit(50)
        .get(const GetOptions(source: Source.server));
  }

}
