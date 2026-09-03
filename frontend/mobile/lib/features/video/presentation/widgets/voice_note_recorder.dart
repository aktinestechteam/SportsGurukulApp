import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
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

class _VoiceNoteRecorderSheet extends StatefulWidget {
  const _VoiceNoteRecorderSheet();

  @override
  State<_VoiceNoteRecorderSheet> createState() => _VoiceNoteRecorderSheetState();
}

class _VoiceNoteRecorderSheetState extends State<_VoiceNoteRecorderSheet> {
  final _recorder = AudioRecorder();
  final _random = Random();

  Timer? _ticker;
  Timer? _waveformTimer;
  int _elapsedSeconds = 0;
  bool _recording = false;
  bool _sending = false;
  bool _sizeTooLarge = false;
  List<double> _barHeights = [6, 12, 8, 14, 9, 16, 7, 13, 6];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRecording());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _waveformTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.show(
          context,
          'Microphone permission is required to record a voice note.',
          type: AppFeedbackType.error,
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        numChannels: 1,
      ),
      path: file.path,
    );
    if (!mounted) {
      return;
    }
    setState(() => _recording = true);

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        return;
      }
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= VideoConstants.maxVoiceNoteDurationSeconds) {
        _onStop();
      }
    });

    _waveformTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted || !_recording) {
        return;
      }
      setState(() {
        _barHeights = [
          for (var i = 0; i < 9; i++)
            (8 + _random.nextDouble() * 16).clamp(6, 24).toDouble(),
        ];
      });
    });
  }

  Future<void> _onStop() async {
    if (!_recording || _sending) {
      return;
    }
    _ticker?.cancel();
    _waveformTimer?.cancel();

    final path = await _recorder.stop();
    if (path == null || !mounted) {
      return;
    }
    final file = File(path);
    final size = file.lengthSync();
    final duration = _elapsedSeconds;

    setState(() {
      _recording = false;
      _sizeTooLarge = size >= VideoConstants.maxVoiceNoteSizeBytes;
    });

    if (_sizeTooLarge) {
      AppSnackbar.show(
        context,
        'Voice note is too large. Must be under ${VideoConstants.maxVoiceNoteSizeBytes ~/ (1024 * 1024)}MB.',
        type: AppFeedbackType.error,
      );
      return;
    }

    await _submit(file.path, size, duration);
  }

  Future<void> _submit(String path, int sizeBytes, int durationSeconds) async {
    setState(() => _sending = true);

    final provider = context.read<VideoProvider>();
    final presigned = await provider.generatePresignedUrl(
      GeneratePresignedUrlInput(
        fileName: 'voice_note.m4a',
        contentType: 'audio/m4a',
        fileSizeBytes: sizeBytes,
      ),
    );
    if (presigned == null) {
      if (mounted) {
        setState(() => _sending = false);
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
      bytes: await File(path).readAsBytes(),
      mimeType: 'audio/m4a',
    );
    if (!mounted) {
      return;
    }
    if (!uploaded) {
      setState(() => _sending = false);
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
        durationSeconds: durationSeconds,
        sizeBytes: sizeBytes,
      ),
    );
  }

  void _onCancel() {
    if (_recording) {
      _recorder.stop();
    }
    Navigator.of(context).pop();
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
              _recording
                  ? 'Recording...'
                  : (_sending ? 'Sending...' : _sizeTooLarge
                        ? 'File too large'
                        : 'Finished'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AuthPalette.subtitle(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                _formatClock(_elapsedSeconds),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _recording ? AuthPalette.red : AuthPalette.textPrimary(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildWaveform(context),
            const SizedBox(height: AppSpacing.xl),
            if (_sending)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else
              Row(
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
                      label: _recording ? 'Stop & Send' : 'Send',
                      icon: Icons.check,
                      onPressed: _recording ? _onStop : null,
                      loading: _sending,
                    ),
                  ),
                ],
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

  Widget _buildWaveform(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _recording ? 1 : 0.4,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final h in _barHeights)
              Container(
                width: 4,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _recording ? AuthPalette.red : AuthPalette.muted(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
