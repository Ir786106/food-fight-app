import '../core/config/local_demo.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import '../core/utils/logger.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

/// One token listener per signed-in account; notification opens can wait for auth.
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static StreamSubscription<String>? _tokenSubscription;
  static bool _initialized = false;
  static String? _userId;
  static Map<String, dynamic>? _pending;
  static void Function(Map<String, dynamic>)? onOpen;
  static void Function(String, Map<String, dynamic>)? onForeground;

  static void routePending() {
    if (onOpen != null && _pending != null) {
      final data = _pending!;
      _pending = null;
      onOpen!(data);
    }
  }
  static void _open(RemoteMessage message) {
    _pending = Map<String, dynamic>.from(message.data);
    routePending();
  }

  static Future<void> initializeListenersOnly() async {
    if (LocalDemo.enabled || _initialized) return;
    _initialized = true;
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title;
        if (title != null) onForeground?.call(title, Map<String, dynamic>.from(message.data));
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_open);
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _open(initial);
    } catch (_) {
      AppLogger.warn('Push notification initialization unavailable', tag: 'FCM');
    }
  }
  static Future<void> initialize() => initializeListenersOnly();

  static Future<NotificationSettings?> requestNotificationPermission() async {
    if (LocalDemo.enabled) return null;
    try { return await _messaging.requestPermission(alert: true, badge: true, sound: true); }
    catch (_) { return null; }
  }

  static Future<void> registerUserToken(String userId) async {
    if (LocalDemo.enabled || userId.isEmpty || (_userId == userId && _tokenSubscription != null)) return;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('push_notifications') ?? true)) return;
    Future<void> save(String token) async {
      if (_userId != userId) return;
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    try {
      final token = await _messaging.getToken();
      if (token != null) await save(token);
      if (_userId != userId) return;
      _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
        save(token).catchError((Object _) {});
      });
    } catch (_) {
      AppLogger.warn('Push token registration unavailable', tag: 'FCM');
    }
  }

  static Future<void> unregisterUserToken() async {
    final userId = _userId;
    _userId = null;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _pending = null;
    if (userId == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(), 'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      await _messaging.deleteToken();
    } catch (_) {
      AppLogger.warn('Push token cleanup could not reach the server', tag: 'FCM');
    }
  }

  static Future<void> setPushEnabled(bool enabled, String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', enabled);
    if (enabled) {
      final settings = await requestNotificationPermission();
      if (settings?.authorizationStatus == AuthorizationStatus.denied) {
        await prefs.setBool('push_notifications', false);
        throw StateError('Enable notifications in your device settings.');
      }
      if (userId != null) await registerUserToken(userId);
    } else {
      await unregisterUserToken();
    }
  }

  static Future<void> setOffersEnabled(bool enabled) => LocalDemo.enabled
      ? Future<void>.value()
      : enabled
      ? _messaging.subscribeToTopic('food_fight_offers')
      : _messaging.unsubscribeFromTopic('food_fight_offers');
}
