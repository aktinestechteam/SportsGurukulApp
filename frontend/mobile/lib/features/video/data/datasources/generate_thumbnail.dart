import 'generate_thumbnail_io.dart'
    if (dart.library.js_interop) 'generate_thumbnail_web.dart' as impl;

/// Cross-platform entry point for extracting a video thumbnail frame.
///
/// On mobile this uses bundled ffmpeg to capture a JPEG frame near [offset].
/// On web ffmpeg is unavailable, so this returns `null` (no thumbnail).
Future<({List<int> bytes, String format})?> generateVideoThumbnail(
  String videoPath, {
  Duration offset = const Duration(seconds: 1),
}) =>
    impl.generateVideoThumbnail(videoPath, offset: offset);
