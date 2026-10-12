import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';
import '../../services/fcm_service.dart';

/// Non-blocking bootstrap orchestrator running in parallel with splash & first frame.
/// Every task is executed concurrently with strict per-task timeouts (4-6s) and
/// resilient try/catch wrappers so it never blocks or crashes the app.
class AppBootstrap {
  static bool _hasStarted = false;
  static bool _hasCompleted = false;

  static bool get hasCompleted => _hasCompleted;

  @visibleForTesting
  static void resetForTesting() {
    _hasStarted = false;
    _hasCompleted = false;
  }

  /// Fire-and-forget background bootstrap trigger
  static Future<void> startBackgroundBootstrap() async {
    if (_hasStarted) return;
    _hasStarted = true;

    final stopwatch = Stopwatch()..start();
    AppLogger.info('[PERF] AppBootstrap started in parallel with splash', tag: 'Bootstrap');

    try {
      await Future.wait([
        _initAppCheck().timeout(
          const Duration(seconds: 4),
          onTimeout: () {
            AppLogger.warn('[AppBootstrap] App Check init timed out (4s), continuing without blocking', tag: 'Bootstrap');
          },
        ),
        _initSupabase().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            AppLogger.warn('[AppBootstrap] Supabase init timed out (5s), continuing without blocking', tag: 'Bootstrap');
          },
        ),
        _initFcmListeners().timeout(
          const Duration(seconds: 4),
          onTimeout: () {
            AppLogger.warn('[AppBootstrap] FCM listeners init timed out (4s), continuing without blocking', tag: 'Bootstrap');
          },
        ),
      ]);
    } catch (e) {
      AppLogger.error('[AppBootstrap] Unexpected bootstrap error: $e', tag: 'Bootstrap');
    } finally {
      stopwatch.stop();
      _hasCompleted = true;
      AppLogger.info('[PERF] AppBootstrap completed in ${stopwatch.elapsedMilliseconds}ms', tag: 'Bootstrap');
    }
  }

  /// App Check activation - strictly non-blocking.
  /// For sideloaded/GitHub APKs, Play Integrity may not be verified by Google Play.
  /// Firebase Console App Check enforcement MUST remain UNENFORCED for GitHub APK distributions.
  static Future<void> _initAppCheck() async {
    try {
      if (kIsWeb) return;
      await FirebaseAppCheck.instance.activate(
        androidProvider: kReleaseMode
            ? AndroidProvider.playIntegrity
            : AndroidProvider.debug,
      );
      AppLogger.info('[AppBootstrap] Firebase App Check activated (${kReleaseMode ? 'playIntegrity' : 'debug'})', tag: 'Bootstrap');
    } catch (e) {
      AppLogger.warn('[AppBootstrap] App Check activation notice (non-fatal): $e', tag: 'Bootstrap');
    }
  }

  /// Supabase Storage initialization
  static Future<void> _initSupabase() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      AppLogger.info('[AppBootstrap] Supabase initialized successfully', tag: 'Bootstrap');
    } catch (e) {
      AppLogger.warn('[AppBootstrap] Supabase init notice (non-fatal): $e', tag: 'Bootstrap');
    }
  }

  /// FCM background & foreground listeners only (NO permission prompt popup here!)
  static Future<void> _initFcmListeners() async {
    try {
      await FcmService.initializeListenersOnly();
      AppLogger.info('[AppBootstrap] FCM background stream listeners registered', tag: 'Bootstrap');
    } catch (e) {
      AppLogger.warn('[AppBootstrap] FCM listeners notice (non-fatal): $e', tag: 'Bootstrap');
    }
  }
}
