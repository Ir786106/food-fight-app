import 'package:cloud_firestore/cloud_firestore.dart';

/// Robust safe conversion utility that prevents all Firestore typing crashes,
/// such as `type 'int' is not a subtype of type 'double' in type cast`
/// and `type 'Timestamp' is not a subtype of type 'int'`.
class SafeConvert {
  /// Safely converts any dynamic value to a double.
  static double toDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is double) return val.isFinite ? val : fallback;
    if (val is int) return val.toDouble();
    if (val is num) return val.isFinite ? val.toDouble() : fallback;
    if (val is String) {
      final parsed = double.tryParse(val);
      return parsed != null && parsed.isFinite ? parsed : fallback;
    }
    return fallback;
  }

  /// Safely converts any dynamic value to an int.
  static int toInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.isFinite ? val.toInt() : fallback;
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  /// Safely converts Firestore Timestamp, int milliseconds, ISO string, or DateTime to DateTime.
  static DateTime toDateTime(dynamic val, [DateTime? fallback]) {
    final defaultDate = fallback ?? DateTime.now();
    if (val == null) return defaultDate;
    if (val is DateTime) return val;
    if (val is Timestamp) return val.toDate();

    if (val is num) {
      return val.isFinite && val.abs() <= 8640000000000000
          ? DateTime.fromMillisecondsSinceEpoch(val.toInt())
          : defaultDate;
    }
    if (val is String) return DateTime.tryParse(val) ?? defaultDate;
    try {
      return (val as dynamic).toDate();
    } catch (_) {
      return defaultDate;
    }
  }

  /// Safely converts dynamic map to Map<String, double>
  static Map<String, double> toDoubleMap(dynamic map) {
    if (map == null || map is! Map) return {};
    final result = <String, double>{};
    map.forEach((k, v) {
      result[k.toString()] = toDouble(v);
    });
    return result;
  }
}
