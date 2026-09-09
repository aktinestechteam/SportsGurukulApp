import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../../../core/config/video_constants.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/repositories/video_repository.dart';
import '../providers/video_provider.dart';
import '../../data/datasources/s3_upload.dart';

class VoiceNoteResult {
  const VoiceNoteResult({
    required this.s3Key,
    required this.durationSeconds,
    required this.sizeBytes,
  });

  final String s3Key;
  final int durationSeconds;
  final int sizeBytes;
}

class VoiceNoteRecorder {
  VoiceNoteRecorder._();

  static Future<VoiceNoteResult?> show(BuildContext context) {
    return showModalBottomSheet<VoiceNoteResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (context) => const _VoiceNoteRecorderSheet(),
    );
  }
}

enum _RecorderPhase { idle, recording, recorded, sending }

class _VoiceNoteRecorderSheet extends StatefulWidget {
  const _VoiceNoteRecorderSheet();

  @override
  State<_VoiceNoteRecorderSheet> createState() => _VoiceNoteRecorderSheetState();
}

class _VoiceNoteRecorderSheetState extends State<_VoiceNoteRecorderSheet> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Timer? _ticker;
  int _elapsedSeconds = 0;
  bool _sizeTooLarge = false;

  _RecorderPhase _phase = _RecorderPhase.idle;
  List<double> _barHeights = List.filled(21, 4);
  final List<double> _levelHistory = List.filled(21, 0.0);
  bool _previewing = false;
  Duration _previewPosition = Duration.zero;
  Duration? _previewDuration;
  String? _filePath;
  Uint8List? _webBytes;

  static const _barCount = 21;

  @override
  void initState() {
    super.initState();
    _subscriptions.add(_recorder.onAmplitudeChanged(
      const Duration(milliseconds: 100),
    ).listen((amplitude) {
      if (!mounted || _phase != _RecorderPhase.recording) {
        return;
      }
      // Amplitude.current is in dBFS (roughly -160 .. 0). Map soft-to-loud
      // speech (-60 dB .. 0 dB) onto a 0..1 scale for the bars.
      final normalized = ((amplitude.current + 60) / 60).clamp(0.0, 1.0);
      setState(() {
        // Keep a rolling window of the last N samples so the bars draw a
        // natural waveform that reflects the real input history.
        _levelHistory.removeAt(0);
        _levelHistory.add(normalized);
        _barHeights = [
          for (final level in _levelHistory) 4 + level * 36,
        ];
      });
    }));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        AppSnackbar.show(
          context,
          'Microphone permission is required to record a voice note.',
          type: AppFeedbackType.error,
        );
      }
      return;
    }

    // On web `record` uses the browser MediaRecorder and ignores the path.
    // On IO platforms a real temporary file path is required.
    final String path;
    if (kIsWeb) {
      path = '';
    } else {
      final dir = await getTemporaryDirectory();
      path =
          '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }

    try {
      // device is left null so Android/iOS select the default input (mic).
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: path,
      );
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          'Could not start recording. Please check microphone access.',
          type: AppFeedbackType.error,
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _phase = _RecorderPhase.recording;
      _elapsedSeconds = 0;
      _filePath = path;
      for (var i = 0; i < _barCount; i++) {
        _levelHistory[i] = 0.0;
      }
      _barHeights = List.filled(_barCount, 4);
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _phase != _RecorderPhase.recording) {
        return;
      }
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= VideoConstants.maxVoiceNoteDurationSeconds) {
        _finishRecording();
      }
    });
  }

  Future<void> _finishRecording() async {
    if (_phase != _RecorderPhase.recording) {
      return;
    }
    _ticker?.cancel();
    _ticker = null;

    String? path;
    int size = 0;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }

    if (path == null || !mounted) {
      return;
    }

    if (kIsWeb) {
      // On web `stop()` returns a blob object URL, not a file path.
      // Fetch the bytes to determine the size (used for validation below).
      final webBytes = await _fetchWebBytes(path);
      if (webBytes == null) {
        if (mounted) {
          AppSnackbar.show(
            context,
            'Could not read the recording. Please try again.',
            type: AppFeedbackType.error,
          );
          setState(() => _phase = _RecorderPhase.recorded);
        }
        return;
      }
      _webBytes = webBytes;
      size = webBytes.length;
    } else {
      size = File(path).lengthSync();
    }

    setState(() {
      _phase = _RecorderPhase.recorded;
      _sizeTooLarge = size >= VideoConstants.maxVoiceNoteSizeBytes;
      _previewing = false;
      _previewPosition = Duration.zero;
      _previewDuration = null;
    });

    if (_sizeTooLarge) {
      if (mounted) {
        AppSnackbar.show(
          context,
          'Voice note is too large. Must be under ${VideoConstants.maxVoiceNoteSizeBytes ~/ (1024 * 1024)}MB.',
          type: AppFeedbackType.error,
        );
      }
      return;
    }

    _loadPreview(path, size);
  }

  Future<Uint8List?> _fetchWebBytes(String blobUrl) async {
    try {
      final response = await http.get(Uri.parse(blobUrl));
      if (response.statusCode != 200) {
        return null;
      }
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadPreview(String path, int sizeBytes) async {
    try {
      if (kIsWeb) {
        // On web `path` is a blob object URL; just_audio plays it via setUrl.
        await _player.setUrl(path);
      } else {
        await _player.setFilePath(path);
      }
      _player.durationStream.listen((d) {
        if (mounted) {
          setState(() => _previewDuration = d);
        }
      });
      _player.positionStream.listen((p) {
        if (mounted) {
          setState(() => _previewPosition = p);
        }
      });
      _player.playerStateStream.listen((state) {
        if (!mounted) {
          return;
        }
        setState(() => _previewing = state.playing);
        if (state.processingState == ProcessingState.completed) {
          _player.pause();
          _player.seek(Duration.zero);
        }
      });
      setState(() => _filePath = path);
    } catch (_) {
      // Preview unavailable; user can still send the recorded file.
    }
  }

  Future<void> _togglePreview() async {
    try {
      if (_previewing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (_) {
      // Ignore playback errors; recording is unaffected.
    }
  }

  Widget _buildPreviewSeek(BuildContext context) {
    final duration = _previewDuration ?? Duration(seconds: _elapsedSeconds);
    final maxSeconds = duration.inMilliseconds.clamp(0, 1 << 30);
    final maxMs = maxSeconds.toDouble();

    void onSeekEnd(double value) {
      _player.seek(Duration(milliseconds: value.round()));
    }

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: AuthPalette.red,
            inactiveTrackColor: AuthPalette.border(context),
            thumbColor: AuthPalette.red,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            min: 0,
            max: maxMs > 0 ? maxMs : 1,
            value: _previewPosition.inMilliseconds
                .clamp(0.0, maxMs > 0 ? maxMs : 1)
                .toDouble(),
            onChanged: (value) {
              setState(
                () => _previewPosition = Duration(milliseconds: value.round()),
              );
            },
            onChangeEnd: onSeekEnd,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _clock(_previewPosition),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AuthPalette.subtitle(context),
              ),
            ),
            Text(
              _clock(duration),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AuthPalette.subtitle(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _reRecord() async {
    _ticker?.cancel();
    _player.stop();
    setState(() {
      _phase = _RecorderPhase.idle;
      _previewing = false;
      _previewPosition = Duration.zero;
      _previewDuration = null;
      _elapsedSeconds = 0;
      _sizeTooLarge = false;
      for (var i = 0; i < _barCount; i++) {
        _levelHistory[i] = 0.0;
      }
      _barHeights = List.filled(_barCount, 4);
    });
    _webBytes = null;
  }

  Future<void> _send() async {
    final path = _filePath;
    if (path == null || _phase != _RecorderPhase.recorded) {
      return;
    }
    final int size = kIsWeb
        ? (_webBytes?.length ?? 0)
        : File(path).lengthSync();
    if (size == 0) {
      if (mounted) {
        AppSnackbar.show(
          context,
          'Recording is empty. Please re-record.',
          type: AppFeedbackType.error,
        );
      }
      return;
    }

    setState(() => _phase = _RecorderPhase.sending);

    final provider = context.read<VideoProvider>();
    final presigned = await provider.generatePresignedUrl(
      GeneratePresignedUrlInput(
        fileName: 'voice_note.m4a',
        contentType: 'audio/m4a',
        fileSizeBytes: size,
      ),
    );
    if (presigned == null) {
      if (mounted) {
        setState(() => _phase = _RecorderPhase.recorded);
        AppSnackbar.show(
          context,
          'Could not prepare the upload. Please try again.',
          type: AppFeedbackType.error,
        );
      }
      return;
    }

    final uploaded = await uploadToPresignedUrl(
      presignedUrl: presigned.uploadUrl,
      bytes: kIsWeb ? (_webBytes ?? Uint8List(0)) : await File(path).readAsBytes(),
      mimeType: 'audio/m4a',
    );
    if (!mounted) {
      return;
    }
    if (!uploaded) {
      setState(() => _phase = _RecorderPhase.recorded);
      AppSnackbar.show(
        context,
        'Upload failed. Please try again.',
        type: AppFeedbackType.error,
      );
      return;
    }

    Navigator.of(context).pop(
      VoiceNoteResult(
        s3Key: presigned.s3Key,
        durationSeconds: _elapsedSeconds,
        sizeBytes: size,
      ),
    );
  }

  void _onCancel() async {
    if (_phase == _RecorderPhase.recording) {
      try {
        await _recorder.stop();
      } catch (_) {}
    }
    _ticker?.cancel();
    _player.stop();
    _webBytes = null;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String get _statusText {
    switch (_phase) {
      case _RecorderPhase.idle:
        return 'Tap to start recording';
      case _RecorderPhase.recording:
        return 'Recording...';
      case _RecorderPhase.recorded:
        return _sizeTooLarge ? 'File too large' : 'Listen before sending';
      case _RecorderPhase.sending:
        return 'Sending...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xs,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AuthPalette.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Voice Note',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _phase == _RecorderPhase.recording
                    ? AuthPalette.red
                    : AuthPalette.subtitle(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                _formatClock(_elapsedSeconds),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _phase == _RecorderPhase.recording
                      ? AuthPalette.red
                      : AuthPalette.textPrimary(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildWaveform(context),
            const SizedBox(height: AppSpacing.xl),
            _buildControls(context),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    switch (_phase) {
      case _RecorderPhase.idle:
        return AppButton(
          label: 'Start Recording',
          icon: Icons.mic,
          onPressed: _startRecording,
        );
      case _RecorderPhase.recording:
        return AppButton(
          label: 'Stop Recording',
          icon: Icons.stop,
          variant: AppButtonVariant.destructive,
          onPressed: _finishRecording,
        );
      case _RecorderPhase.recorded:
        if (_sizeTooLarge) {
          return Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.outlined,
                  onPressed: _onCancel,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Re-record',
                  onPressed: _reRecord,
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            AppButton(
              label: _previewing ? 'Pause preview' : 'Listen',
              icon: _previewing ? Icons.pause : Icons.play_arrow,
              variant: AppButtonVariant.outlined,
              onPressed: _togglePreview,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildPreviewSeek(context),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Re-record',
                    variant: AppButtonVariant.outlined,
                    onPressed: _reRecord,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    label: 'Send',
                    icon: Icons.send,
                    onPressed: _send,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _formatPreviewClock(_previewPosition, _previewDuration),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AuthPalette.subtitle(context),
              ),
            ),
          ],
        );
      case _RecorderPhase.sending:
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
    }
  }

  Widget _buildWaveform(BuildContext context) {
    final active =
        _phase == _RecorderPhase.recording || _phase == _RecorderPhase.recorded;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: active ? 1 : 0.4,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final h in _barHeights)
              Container(
                width: 3,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _phase == _RecorderPhase.recording
                      ? AuthPalette.red
                      : AuthPalette.muted(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatClock(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPreviewClock(Duration position, Duration? duration) {
    final total = duration ?? Duration(seconds: _elapsedSeconds);
    return '${_clock(position)} / ${_clock(total)}';
  }

  String _clock(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
