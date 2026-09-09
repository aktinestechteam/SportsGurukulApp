import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:video_player/video_player.dart';

/// Generates a thumbnail from a video file on mobile.
///
/// Uses [VideoPlayerController] to render a single frame off-screen via an
/// [OverlayEntry] and captures it with a [RepaintBoundary].
Future<({List<int> bytes, String format})?> generateVideoThumbnail(
  String videoPath, {
  Duration offset = const Duration(seconds: 1),
  BuildContext? context,
}) async {
  if (context == null) return null;

  // Capture the overlay state before any async gaps to satisfy the linter.
  final overlayState = Overlay.of(context, rootOverlay: true);

  final controller = VideoPlayerController.file(File(videoPath));
  try {
    await controller.initialize();
    await controller.seekTo(offset);
    // Allow the first frame to render after seeking.
    await Future.delayed(const Duration(milliseconds: 600));

    final key = GlobalKey();
    final completer = Completer<({List<int> bytes, String format})?>();

    late OverlayEntry overlay;
    overlay = OverlayEntry(
      builder: (_) => Positioned(
        left: -1000,
        top: -1000,
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: 640,
            height: 360,
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlay);

    // Give the platform texture time to paint into the off-screen area.
    await Future.delayed(const Duration(milliseconds: 500));

    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      overlay.remove();
      completer.complete(null);
    } else {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      overlay.remove();

      if (byteData != null) {
        completer.complete((
          bytes: byteData.buffer.asUint8List(),
          format: 'png',
        ));
      } else {
        completer.complete(null);
      }
    }

    return completer.future;
  } catch (_) {
    return null;
  } finally {
    controller.dispose();
  }
}
