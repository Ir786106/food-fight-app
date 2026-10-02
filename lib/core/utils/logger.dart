import 'package:flutter/foundation.dart';

/// Utility class for logging
class AppLogger {
  static void debug(String message, {String? tag}) {
    final prefixedMessage = tag != null ? '[$tag] $message' : message;
    debugPrint('DEBUG: $prefixedMessage');
  }

  static void info(String message, {String? tag}) {
    final prefixedMessage = tag != null ? '[$tag] $message' : message;
    debugPrint('INFO: $prefixedMessage');
  }

  static void warning(String message, {String? tag}) {
    final prefixedMessage = tag != null ? '[$tag] $message' : message;
    debugPrint('WARNING: $prefixedMessage');
  }

  static void warn(String message, {String? tag}) => warning(message, tag: tag);

  static void error(String message, {dynamic error, StackTrace? stackTrace, String? tag}) {
    final prefixedMessage = tag != null ? '[$tag] $message' : message;
    debugPrint('ERROR: $prefixedMessage');
    if (error != null) {
      debugPrint('  Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('  StackTrace: $stackTrace');
    }
  }

  static void severe(String message, {dynamic error, StackTrace? stackTrace}) {
    debugPrint('SEVERE: $message');
    if (error != null) {
      debugPrint('  Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('  StackTrace: $stackTrace');
    }
  }

  static void wtf(String message, {dynamic error, StackTrace? stackTrace}) {
    debugPrint('WTF: $message');
    if (error != null) {
      debugPrint('  Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('  StackTrace: $stackTrace');
    }
  }
}
