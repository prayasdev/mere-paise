import 'package:intl/intl.dart';

class LedgerDateUtils {
  LedgerDateUtils._();

  static final DateFormat _dayKeyFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthKeyFormat = DateFormat('yyyy-MM');
  static final DateFormat _yearKeyFormat = DateFormat('yyyy');
  static final DateFormat _displayDateFormat = DateFormat('EEE, d MMM yyyy');
  static final DateFormat _shortDateFormat = DateFormat('d MMM');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _monthHeaderFormat = DateFormat('MMMM yyyy');

  static String dayKey(DateTime dt) => _dayKeyFormat.format(dt);
  static String monthKey(DateTime dt) => _monthKeyFormat.format(dt);
  static String yearKey(DateTime dt) => _yearKeyFormat.format(dt);

  /// ISO 8601 Week key, e.g. "2026-W45"
  static String weekKey(DateTime dt) {
    // Determine ISO 8601 week number
    final int dayOfYear = int.parse(DateFormat('D').format(dt));
    final int woy = ((dayOfYear - dt.weekday + 10) / 7).floor();
    final String weekStr = woy.toString().padLeft(2, '0');
    return '${dt.year}-W$weekStr';
  }

  static String formatDisplayDate(DateTime dt) => _displayDateFormat.format(dt);
  static String formatShortDate(DateTime dt) => _shortDateFormat.format(dt);
  static String formatTime(DateTime dt) => _timeFormat.format(dt);
  static String formatMonthHeader(DateTime dt) => _monthHeaderFormat.format(dt);

  /// Day header text: "Today", "Yesterday", or "Wed, 4 Nov 2026"
  static String formatRelativeDay(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);

    final diffDays = today.difference(target).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    return _displayDateFormat.format(dt);
  }

  /// Calculates start and end of week respecting weekStartsOn (1 = Monday, 7 = Sunday)
  static DateTime getStartOfWeek(DateTime dt, {int weekStartsOn = 1}) {
    final int currentWeekday = dt.weekday; // 1 (Mon) .. 7 (Sun)
    final int diff = (currentWeekday - weekStartsOn + 7) % 7;
    final start = dt.subtract(Duration(days: diff));
    return DateTime(start.year, start.month, start.day);
  }

  /// Time-of-day bucket for Day insight: "Morning" (06-12), "Afternoon" (12-17), "Evening" (17-21), "Night" (21-06)
  static String getTimeOfDayBucket(DateTime dt) {
    final hour = dt.hour;
    if (hour >= 6 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 21) return 'Evening';
    return 'Night';
  }
}

