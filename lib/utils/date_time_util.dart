import 'package:cloud_firestore/cloud_firestore.dart';

/// Robust, crash-proof date parsing utility for Firestore and API data.
///
/// Handles `DateTime`, Firestore `Timestamp`, ISO8601 `String`, and numeric epoch values
/// without throwing runtime `TypeError` or `FormatException`.
class DateTimeUtil {
  DateTimeUtil._();

  /// Parses any [value] into a [DateTime].
  ///
  /// If [value] cannot be parsed or is null, returns [fallback] or `DateTime.now()`.
  static DateTime parse(dynamic value, {DateTime? fallback}) {
    final parsed = tryParse(value);
    return parsed ?? fallback ?? DateTime.now();
  }

  /// Tries to parse any [value] into a [DateTime], returning `null` on failure or if [value] is null.
  static DateTime? tryParse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();

    // Check for duck-typed Timestamp (e.g. from dynamic object with toDate)
    try {
      if (value is! String && value is! num) {
        final dynamic dynamicVal = value;
        if (dynamicVal.toDate is Function) {
          final result = dynamicVal.toDate();
          if (result is DateTime) return result;
        }
      }
    } catch (_) {}

    if (value is num) {
      final intVal = value.toInt();
      // If value is in seconds (10 digits, e.g. < 10000000000), convert to ms
      if (intVal > 0 && intVal < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(intVal);
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final dt = DateTime.tryParse(trimmed);
      if (dt != null) return dt;

      // Try numeric string
      final numVal = int.tryParse(trimmed);
      if (numVal != null) {
        return tryParse(numVal);
      }
    }

    return null;
  }
}
