import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';

class RiderLocationData {
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final DateTime updatedAt;
  final bool isActive;

  RiderLocationData({
    required this.latitude,
    required this.longitude,
    this.heading = 0.0,
    this.speed = 0.0,
    required this.updatedAt,
    this.isActive = true,
  });

  factory RiderLocationData.fromMap(Map<String, dynamic> data) {
    return RiderLocationData(
      latitude: (data['latitude'] as num?)?.toDouble() ?? 31.5204,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 74.3587,
      heading: (data['heading'] as num?)?.toDouble() ?? 0.0,
      speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }
}

class RiderLocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Broadcast live GPS coordinates for an active delivery order
  static Future<void> updateOrderRiderLocation({
    required String orderId,
    required String riderId,
    required double latitude,
    required double longitude,
    double heading = 0.0,
    double speed = 0.0,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).collection('tracking').doc('rider_live').set({
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'riderId': riderId,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update in global active rider pool for fleet view
      await _firestore.collection('rider_locations').doc(riderId).set({
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'activeOrderId': orderId,
        'isOnline': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('Failed to update rider location: $e', tag: 'RiderLocationService');
    }
  }

  /// Subscribe to live rider coordinates for a specific order
  static Stream<RiderLocationData?> watchOrderRiderLocation(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .collection('tracking')
        .doc('rider_live')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RiderLocationData.fromMap(doc.data()!);
    });
  }

  /// Stop broadcasting once an order is delivered or cancelled (preserves battery & privacy)
  static Future<void> stopBroadcasting({
    required String orderId,
    required String riderId,
  }) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('tracking')
          .doc('rider_live')
          .update({'isActive': false});

      await _firestore.collection('rider_locations').doc(riderId).update({
        'activeOrderId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Stopped location broadcasting for order $orderId', tag: 'RiderLocationService');
    } catch (e) {
      AppLogger.error('Failed to stop broadcasting: $e', tag: 'RiderLocationService');
    }
  }
}
