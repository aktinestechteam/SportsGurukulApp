import 'package:flutter/widgets.dart';

import 'generate_thumbnail_io.dart'
    if (dart.library.js_interop) 'generate_thumbnail_web.dart' as impl;

/// Cross-platform entry point for extracting a video thumbnail frame.
///
/// On mobile this uses [VideoPlayerController] to render a frame off-screen
/// and capture it. On web the function returns `null` (no thumbnail).
Future<({List<int> bytes, String format})?> generateVideoThumbnail(
  String videoPath, {
  Duration offset = const Duration(seconds: 1),
  BuildContext? context,
}) =>
    impl.generateVideoThumbnail(videoPath, offset: offset, context: context);
