/// Shared formatting helpers for the video feature (durations, dates).
class VideoFormat {
  VideoFormat._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Formats a duration in seconds as `m:ss` (e.g. `2:05`).
  static String duration(int seconds) {
    final clamped = seconds < 0 ? 0 : seconds;
    final m = clamped ~/ 60;
    final s = clamped % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static DateTime? parseDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  /// A short date label like `Aug 31, 2026`.
  static String dateLabel(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';

  /// Group key for a video's creation date: `Today`, `Yesterday`, or `Older`.
  static String groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return 'Older';
  }

  /// A compact relative time label like `just now`, `5m ago`, or `2h ago`.
  static String timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return dateLabel(date);
  }

  static String timeAgoString(String? iso) => timeAgo(parseDate(iso));
}
