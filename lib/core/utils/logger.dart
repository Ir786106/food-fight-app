/// Utility class for logging
class AppLogger {
  static void debug(String message, {String? tag}) {
    final prefixedMessage = tag != null ? '[$tag] $message' : message;
    print('DEBUG: $prefixedMessage');
  }

  static void info(String message, {String? tag}) {
    final prefixedMessage = tag != null ? '[$tag] $message' : message;
    print('INFO: $prefixedMessage');
  }

  static void warning(String message, {String? tag}) {
    final prefixedMessage = tag != null ? '[$tag] $message' : message;
    print('WARNING: $prefixedMessage');
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace, String? tag}) {
    final prefixedMessage = tag != null ? '[$tag] $message' : message;
    print('ERROR: $prefixedMessage');
    if (error != null) {
      print('  Error: $error');
    }
    if (stackTrace != null) {
      print('  StackTrace: $stackTrace');
    }
  }

  static void severe(String message, {dynamic error, StackTrace? stackTrace}) {
    print('SEVERE: $message');
    if (error != null) {
      print('  Error: $error');
    }
    if (stackTrace != null) {
      print('  StackTrace: $stackTrace');
    }
  }

  static void wtf(String message, {dynamic error, StackTrace? stackTrace}) {
    print('WTF: $message');
    if (error != null) {
      print('  Error: $error');
    }
    if (stackTrace != null) {
      print('  StackTrace: $stackTrace');
    }
  }
}
