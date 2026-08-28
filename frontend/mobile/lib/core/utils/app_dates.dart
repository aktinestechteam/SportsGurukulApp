/// Shared helpers for batch date ranges, which are pure calendar dates
/// (no time of day).
///
/// The API stores them as UTC-midnight timestamps and returns ISO-8601
/// strings. These helpers convert between a calendar date and the wire format
/// without any timezone shifting, so the day a coach picks is always the day
/// that renders, regardless of the device's timezone.
class AppDates {
  AppDates._();

  /// ISO string for the UTC midnight of [date]'s calendar date.
  /// e.g. `2026-09-01` -> `2026-09-01T00:00:00.000Z`
  static String toIsoDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).toIso8601String();

  /// Parses a wire value into a calendar date-only [DateTime].
  ///
  /// UTC instants are read back using their UTC components so the wall date is
  /// preserved across timezones.
  static DateTime? parseIsoDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}