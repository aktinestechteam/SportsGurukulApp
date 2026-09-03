/// Web stub: ffmpeg_kit does not support Flutter Web, so thumbnails are not
/// generated in the browser and [generateVideoThumbnail] always returns null.
Future<({List<int> bytes, String format})?> generateVideoThumbnail(
  String videoPath, {
  Duration offset = const Duration(seconds: 1),
}) async {
  return null;
}
