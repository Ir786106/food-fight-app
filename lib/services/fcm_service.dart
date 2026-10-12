import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_collections.dart';
import '../core/utils/logger.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('FCM Background message: ${message.messageId} - ${message.notification?.title}', tag: 'FCM');
}

/// Central service for FCM token registration, notifications permission, and background handling
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize background and foreground listeners without requesting permissions
  static Future<void> initializeListenersOnly() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info('FCM Foreground message received: ${message.notification?.title}', tag: 'FCM');
      });
    } catch (e) {
      AppLogger.warn('FCM listeners initialization warning: $e', tag: 'FCM');
    }
  }

  /// Request notification permissions on-demand (e.g. during onboarding primer or after login)
  static Future<NotificationSettings?> requestNotificationPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.info('FCM Notification permission status: ${settings.authorizationStatus}', tag: 'FCM');
      return settings;
    } catch (e) {
      AppLogger.warn('FCM permission request warning: $e', tag: 'FCM');
      return null;
    }
  }

  /// Backward-compatible initialize method (now listeners only, non-blocking)
  static Future<void> initialize() async {
    await initializeListenersOnly();
  }

  /// Register FCM push token under the user document in Cloud Firestore
  static Future<void> registerUserToken(String userId) async {
    if (userId.isEmpty) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .doc(userId)
            .set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        AppLogger.info('FCM Token registered for user $userId', tag: 'FCM');
      }

      // Also listen to token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .doc(userId)
            .set({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      AppLogger.warn('Failed to register FCM token for user $userId: $e', tag: 'FCM');
    }
  }
}
