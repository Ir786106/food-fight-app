import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rider_model.dart';
import '../models/order_model.dart';
import '../core/constants/firestore_collections.dart';
import '../core/utils/logger.dart';

class RiderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _ridersCol =
      _firestore.collection(FirestoreCollections.riders);
  static final CollectionReference _ordersCol =
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
    FirebaseApp? tempApp;
    try {
      final appName = 'RiderAuthApp_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final cred = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName(name.trim());

      // 1. Save user document in 'users' collection with delivery_rider role
      await _firestore.collection(FirestoreCollections.users).doc(uid).set({
        'id': uid,
        'uid': uid,
        'email': email.trim().toLowerCase(),
        'name': name.trim(),
        'phone': phone.trim(),
        'role': 'delivery_rider',
        'status': 'active',
        'isActive': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Save rider document in 'riders' collection
      final riderDoc = _ridersCol.doc(uid);
      await riderDoc.set({
        'id': uid,
        'userId': uid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'vehicleType': vehicleType ?? 'Motorcycle',
        'vehicleNumber': vehicleNumber,
        'isActive': 1,
        'isOnline': 0,
        'rating': 5.0,
        'totalDeliveries': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.info('Registered rider user $email with UID $uid', tag: 'RiderService');
      return uid;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('FirebaseAuthException creating rider: ${e.code}', tag: 'RiderService');
      if (e.code == 'email-already-in-use') {
        throw 'This email is already registered. Please use a different email.';
      } else if (e.code == 'weak-password') {
        throw 'Password must be at least 6 characters long.';
      } else if (e.code == 'invalid-email') {
        throw 'The email address is badly formatted.';
      }
      throw e.message ?? 'Authentication error occurred.';
    } catch (e) {
      AppLogger.error('Failed to create rider with auth: $e', tag: 'RiderService');
      rethrow;
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

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

      // Also ensure user document reflects the 'delivery_rider' role
      if (rider.userId.isNotEmpty) {
        await _firestore.collection(FirestoreCollections.users).doc(rider.userId).set({
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

      // Record assignment in riderAssignments collection
      await _firestore.collection(FirestoreCollections.riderAssignments).add({
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
  static Stream<List<OrderModel>> watchRiderDeliveries(String riderId, {String? riderPhone}) {
    return _ordersCol.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return OrderModel.fromJson(data);
      }).where((o) {
        if (o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled) {
          return false;
        }
        if (o.riderId != null && o.riderId == riderId) return true;
        if (riderPhone != null && riderPhone.isNotEmpty && o.riderPhone == riderPhone) {
          return true;
        }
        return false;
      }).toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Watch completed deliveries for a specific rider
  static Stream<List<OrderModel>> watchRiderHistory(String riderId, {String? riderPhone}) {
    return _ordersCol.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return OrderModel.fromJson(data);
      }).where((o) {
        if (o.status != OrderStatus.delivered) return false;
        if (o.riderId != null && o.riderId == riderId) return true;
        if (riderPhone != null && riderPhone.isNotEmpty && o.riderPhone == riderPhone) {
          return true;
        }
        return false;
      }).toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
