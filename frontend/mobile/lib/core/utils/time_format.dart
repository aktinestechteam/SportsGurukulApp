/// Shared helpers for formatting schedule times and weekday labels.
///
/// Times travel as 24h `"HH:mm"` strings (coach profile) or `"HH:mm:ss"`
/// strings (batch `TimeOnly` serialization). Every screen renders them the
/// same way — 12h labels like `"05:00 PM"` — so the same batch reads
/// identically on the manage list, edit forms, coach dashboard, and calendar.
///
/// Day-of-week values use the API convention (C# `System.DayOfWeek`): 0 =
/// Sunday … 6 = Saturday.
class TimeFormat {
  TimeFormat._();

  /// Parses `"HH:mm"` or `"HH:mm:ss"` into a 12-hour label (`"05:00 PM"`).
  /// Input that cannot be parsed as a clock is returned unchanged.
  static String clock(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) return raw;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  static const _short = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _full = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  /// Short weekday label for an API day-of-week (0 = Sunday … 6 = Saturday).
  static String shortDay(int apiDayOfWeek) =>
      (apiDayOfWeek >= 0 && apiDayOfWeek < _short.length)
          ? _short[apiDayOfWeek]
          : '';

  /// Full weekday label for an API day-of-week (0 = Sunday … 6 = Saturday).
  static String fullDay(int apiDayOfWeek) =>
      (apiDayOfWeek >= 0 && apiDayOfWeek < _full.length)
          ? _full[apiDayOfWeek]
          : '';
}