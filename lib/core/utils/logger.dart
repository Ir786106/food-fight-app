import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message, {String? tag}) {
    if (kDebugMode) _log(message, 500, tag: tag);
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) _log(message, 800, tag: tag);
  }

  static void warning(String message, {String? tag}) =>
      _log(message, 900, tag: tag);

  static void warn(String message, {String? tag}) => warning(message, tag: tag);

  static void error(String message,
          {dynamic error, StackTrace? stackTrace, String? tag}) =>
      _log(message, 1000, tag: tag, error: error, stackTrace: stackTrace);

  static void severe(String message, {dynamic error, StackTrace? stackTrace}) =>
      _log(message, 1100, error: error, stackTrace: stackTrace);

  static void wtf(String message, {dynamic error, StackTrace? stackTrace}) =>
      _log(message, 1200, error: error, stackTrace: stackTrace);

  static void _log(String message, int level,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? 'FoodFight',
      level: level,
      error: kDebugMode ? error : null,
      stackTrace: kDebugMode ? stackTrace : null,
    );
  }
}
