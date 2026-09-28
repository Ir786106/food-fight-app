import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../core/constants/firestore_collections.dart';
import '../core/utils/logger.dart';
import 'interfaces/notification_service_interface.dart';

class NotificationService implements INotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference _col() {
    return _firestore.collection(FirestoreCollections.notifications);
  }

  /// Watch real-time stream of notifications for a user
  static Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _col()
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return NotificationModel.fromJson(data);
      }).toList();

      // Sort newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final snap = await _col().where('userId', isEqualTo: userId).get();
      final list = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return NotificationModel.fromJson(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      AppLogger.error('Failed to get notifications: $e', tag: 'NotificationService');
      return [];
    }
  }

  @override
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    try {
      final snap = await _col()
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: 0)
          .get();
      final list = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return NotificationModel.fromJson(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      AppLogger.error('Failed to get unread notifications: $e', tag: 'NotificationService');
      return [];
    }
  }

  @override
  Future<NotificationModel?> getNotificationById(String notificationId) async {
    try {
      final doc = await _col().doc(notificationId).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return NotificationModel.fromJson(data);
    } catch (e) {
      AppLogger.error('Failed to get notification: $e', tag: 'NotificationService');
      return null;
    }
  }

  @override
  Future<NotificationModel?> createNotification(NotificationModel notification) async {
    try {
      final docRef = _col().doc();
      final data = notification.toJson();
      data['id'] = docRef.id;
      await docRef.set(data);
      AppLogger.info('Created notification ${docRef.id} for user ${notification.userId}', tag: 'NotificationService');
      return notification.copyWith(isRead: notification.isRead);
    } catch (e) {
      AppLogger.error('Failed to create notification: $e', tag: 'NotificationService');
      return null;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _col().doc(notificationId).update({'isRead': 1});
      AppLogger.info('Marked notification $notificationId as read', tag: 'NotificationService');
    } catch (e) {
      AppLogger.error('Failed to mark notification as read: $e', tag: 'NotificationService');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final unread = await _col()
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: 0)
          .get();

      final batch = _firestore.batch();
      for (var doc in unread.docs) {
        batch.update(doc.reference, {'isRead': 1});
      }
      await batch.commit();
      AppLogger.info('Marked all notifications as read for $userId', tag: 'NotificationService');
    } catch (e) {
      AppLogger.error('Failed to mark all as read: $e', tag: 'NotificationService');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _col().doc(notificationId).delete();
      AppLogger.info('Deleted notification $notificationId', tag: 'NotificationService');
    } catch (e) {
      AppLogger.error('Failed to delete notification: $e', tag: 'NotificationService');
    }
  }

  @override
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final docs = await _col().where('userId', isEqualTo: userId).get();
      final batch = _firestore.batch();
      for (var doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      AppLogger.info('Deleted all notifications for $userId', tag: 'NotificationService');
    } catch (e) {
      AppLogger.error('Failed to delete all notifications: $e', tag: 'NotificationService');
    }
  }

  @override
  Future<void> sendOrderUpdateNotification(
    String userId,
    String orderId,
    String status,
  ) async {
    final title = 'Order Update: ${_formatStatus(status)}';
    final message = 'Your order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId} is now ${_formatStatus(status).toLowerCase()}.';

    final notification = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      message: message,
      type: 'order',
      referenceId: orderId,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  @override
  Future<void> sendPushNotification({
    required String title,
    required String message,
    required String userId,
    String? type,
    String? referenceId,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      message: message,
      type: type ?? 'general',
      referenceId: referenceId,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Received';
      case 'confirmed':
        return 'Confirmed by Kitchen';
      case 'preparing':
        return 'Preparing your Food';
      case 'ready_for_pickup':
      case 'ready':
        return 'Ready for Pickup';
      case 'out_for_delivery':
        return 'Out for Delivery 🚴';
      case 'delivered':
        return 'Delivered 🎉';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
