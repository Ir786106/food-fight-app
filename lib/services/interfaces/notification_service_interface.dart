import 'package:food_fight/models/notification_model.dart';

/// Interface for notification service
abstract class INotificationService {
  /// Get all notifications for user
  Future<List<NotificationModel>> getUserNotifications(String userId);

  /// Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications(String userId);

  /// Get notification by ID
  Future<NotificationModel?> getNotificationById(String notificationId);

  /// Create notification
  Future<NotificationModel?> createNotification(NotificationModel notification);

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId);

  /// Delete notification
  Future<void> deleteNotification(String notificationId);

  /// Delete all notifications for user
  Future<void> deleteAllNotifications(String userId);

  /// Send order update notification
  Future<void> sendOrderUpdateNotification(
    String userId,
    String orderId,
    String status,
  );

  /// Send push notification
  Future<void> sendPushNotification({
    required String title,
    required String message,
    required String userId,
    String? type,
    String? referenceId,
  });
}
