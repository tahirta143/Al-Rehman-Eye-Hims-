import 'package:intl/intl.dart';

/// Standardizes date formatting across the HIMS application.
/// Format: 13 Mar 2026 (d MMM yyyy)
class AppDateFormatter {
  static String format(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  static String formatWithDay(DateTime date) {
    return DateFormat('EEEE, d MMM yyyy').format(date);
  }

  static String formatShort(DateTime date) {
    return DateFormat('d MMM').format(date);
  }
}
