import 'package:intl/intl.dart';

class DateHelper {
  /// Returns the current time.
  static DateTime now() => DateTime.now();

  /// Formats a [DateTime] object into `yyyy-MM-dd HH:mm:ss` for database storage.
  static String? toDatabase(DateTime? date) {
    if (date == null) return null;
    return date.toUtc().toIso8601String();
  }

  /// Formats a [DateTime] object into ISO 8601 for API response.
  static String? toResponse(DateTime? date) {
    return date?.toUtc().toIso8601String();
  }

  /// Parses a string into [DateTime]. Returns `null` if invalid.
  static DateTime? parse(String? value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      try {
        return DateFormat('yyyy-MM-dd HH:mm:ss').parseStrict(value);
      } catch (_) {
        return null;
      }
    }
  }

  /// Parses from Unix timestamp.
  static DateTime fromTimestamp(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  /// Returns current timestamp (in seconds).
  static int currentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  /// Returns difference between [from] and [to] as human readable string.
  static String timeAgo(DateTime from, {DateTime? to}) {
    final now = to ?? DateTime.now();
    final diff = now.difference(from);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minute(s) ago';
    if (diff.inHours < 24) return '${diff.inHours} hour(s) ago';
    if (diff.inDays < 7) return '${diff.inDays} day(s) ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} week(s) ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} month(s) ago';
    return '${(diff.inDays / 365).floor()} year(s) ago';
  }

  /// Checks if date is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  /// Checks if date is yesterday.
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Checks if date is in the future.
  static bool isFuture(DateTime date) => date.isAfter(DateTime.now());

  /// Checks if date is in the past.
  static bool isPast(DateTime date) => date.isBefore(DateTime.now());

  /// Returns beginning of day (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Returns end of day (23:59:59.999)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Adds [days] to date.
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Subtracts [days] from date.
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  /// Converts a date to a custom format.
  static String custom(DateTime date, String format) {
    return DateFormat(format).format(date);
  }

  /// Format localized (requires Intl locale setup).
  static String localized(DateTime date, String locale,
      {String pattern = 'yMMMMd'}) {
    return DateFormat(pattern, locale).format(date);
  }
}
