import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';

/// Extracts a thumbnail frame from a local video file using bundled ffmpeg.
///
/// Runs ffmpeg on a mobile device to grab a single frame near [offset] and
/// returns the JPEG bytes plus their format. Returns `null` when the video
/// cannot be decoded or no frame could be captured.
Future<({List<int> bytes, String format})?> generateVideoThumbnail(
  String videoPath, {
  Duration offset = const Duration(seconds: 1),
}) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final outPath =
        '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

    for (final seconds in [offset.inSeconds, 0]) {
      final command =
          '-ss $seconds -i $videoPath -frames:v 1 -vf scale=-2:360 -q:v 5 -y $outPath';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final outputFile = File(outPath);
      if (ReturnCode.isSuccess(returnCode) && await outputFile.exists()) {
        final length = await outputFile.length();
        if (length > 0) {
          final bytes = await outputFile.readAsBytes();
          await outputFile.delete().catchError((_) => outputFile);
          return (bytes: bytes, format: 'jpg');
        }
      }
    }
  } catch (_) {
    // Fall back to no thumbnail.
  }
  return null;
}
