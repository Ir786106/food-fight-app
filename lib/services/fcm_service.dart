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

  /// Initialize FCM permissions and stream listeners
  static Future<void> initialize() async {
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

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info('FCM Foreground message received: ${message.notification?.title}', tag: 'FCM');
      });
    } catch (e) {
      AppLogger.warn('FCM initialization warning: $e', tag: 'FCM');
    }
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
