import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart' hide VideoFormat;

import '../../../../core/config/video_constants.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/app_ambient_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../athlete/domain/entities/athlete_profile.dart';
import '../../../athlete/presentation/providers/athlete_profile_provider.dart';
import '../../domain/repositories/video_repository.dart';
import '../providers/video_provider.dart';
import '../widgets/video_format.dart';
import '../../data/datasources/generate_thumbnail.dart';
import '../../data/datasources/s3_upload.dart';

class VideoUploadPage extends StatefulWidget {
  const VideoUploadPage({super.key});

  @override
  State<VideoUploadPage> createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _title;
  late final TextEditingController _message;

  String? _selectedSportId;
  XFile? _video;
  int? _durationSeconds;
  int _fileSizeBytes = 0;
  ({List<int> bytes, String format})? _thumbnail;

  late final AnimationController _progressController;
  double _progress = 0;
  bool _uploading = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _message = TextEditingController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        setState(() => _progress = _progressController.value);
      });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  List<AthleteSportInfo> get _sports =>
      context.read<AthleteProfileProvider>().profile?.sports ?? const [];

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: VideoConstants.maxVideoDurationSeconds),
    );
    if (picked == null || !mounted) {
      return;
    }

    if (!_isMp4(picked.name)) {
      AppSnackbar.show(
        context,
        'Only MP4 videos are supported. Please choose an MP4 (.mp4) file.',
        type: AppFeedbackType.error,
      );
      return;
    }

    final size = await picked.length();
    final duration = await _probeDuration(picked.path);
    if (!mounted) {
      return;
    }

    if (size >= VideoConstants.maxVideoSizeBytes) {
      AppSnackbar.show(
        context,
        'Video is too large. Must be under ${VideoConstants.maxVideoSizeBytes ~/ (1024 * 1024)}MB.',
        type: AppFeedbackType.error,
      );
      return;
    }

    if (duration != null && duration >= VideoConstants.maxVideoDurationSeconds) {
      AppSnackbar.show(
        context,
        'Video is too long. Must be under ${VideoConstants.maxVideoDurationSeconds}s.',
        type: AppFeedbackType.error,
      );
      return;
    }

    setState(() {
      _video = picked;
      _fileSizeBytes = size;
      _durationSeconds = duration;
      _progress = 0;
    });

    _captureThumbnail(picked.path);
  }

  Future<void> _captureThumbnail(String path) async {
    final thumb = await generateVideoThumbnail(path);
    if (thumb == null || !mounted) {
      return;
    }
    setState(() => _thumbnail = thumb);
  }

  Future<int?> _probeDuration(String path) async {
    try {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      final duration = controller.value.duration.inSeconds;
      controller.dispose();
      return duration <= 0 ? null : duration;
    } catch (_) {
      return null;
    }
  }

  Future<void> _upload() async {
    final video = _video;
    if (video == null) {
      AppSnackbar.show(
        context,
        'Choose a video from your gallery first.',
        type: AppFeedbackType.warning,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    final provider = context.read<VideoProvider>();
    final contentType = _mimeType(video.name);
    final presigned = await provider.generatePresignedUrl(
      GeneratePresignedUrlInput(
        fileName: video.name,
        contentType: contentType,
        fileSizeBytes: _fileSizeBytes,
      ),
    );
    if (presigned == null) {
      if (!mounted) {
        return;
      }
      setState(() => _uploading = false);
      AppSnackbar.show(
        context,
        'Could not prepare the upload. Please try again.',
        type: AppFeedbackType.error,
      );
      return;
    }
    if (!mounted) {
      return;
    }

    // Real byte upload to the presigned S3 URL.
    // XFile.readAsBytes() works on both mobile and Flutter Web (dart:io's
    // File does not exist on web, which made the upload hang at 0% there).
    final uploaded = await uploadToPresignedUrl(
      presignedUrl: presigned.uploadUrl,
      bytes: await video.readAsBytes(),
      mimeType: contentType,
    );
    if (!mounted) {
      return;
    }
    if (!uploaded) {
      setState(() => _uploading = false);
      AppSnackbar.show(
        context,
        'Upload failed. Please try again.',
        type: AppFeedbackType.error,
      );
      return;
    }

    // Animate progress 0 -> 100% over 2 seconds as visual feedback.
    await _progressController.forward(from: 0);
    if (!mounted) {
      return;
    }

    // Upload the thumbnail (if one was captured on mobile) so the feed can
    // show a real preview instead of the placeholder. On web this is a no-op.
    String? thumbnailS3Key;
    final thumbnail = _thumbnail;
    if (thumbnail != null) {
      final thumbContentType = 'image/${thumbnail.format}';
      final thumbPresigned = await provider.generatePresignedUrl(
        GeneratePresignedUrlInput(
          fileName: 'thumbnail.${thumbnail.format}',
          contentType: thumbContentType,
          fileSizeBytes: thumbnail.bytes.length,
        ),
      );
      if (thumbPresigned != null &&
          thumbPresigned.s3Key.isNotEmpty &&
          await uploadToPresignedUrl(
            presignedUrl: thumbPresigned.uploadUrl,
            bytes: thumbnail.bytes,
            mimeType: thumbContentType,
          )) {
        thumbnailS3Key = thumbPresigned.s3Key;
      }
      if (!mounted) {
        return;
      }
    }

    final input = CreateVideoInput(
      title: _title.text.trim(),
      message: _message.text.trim().isEmpty ? null : _message.text.trim(),
      s3Key: presigned.s3Key,
      thumbnailS3Key: thumbnailS3Key,
      durationSeconds: _durationSeconds,
      fileSizeBytes: _fileSizeBytes,
      sportId: _selectedSportId,
    );

    final ok = await provider.createVideo(input);
    if (!mounted) {
      return;
    }

    if (ok) {
      setState(() => _success = true);
      AppSnackbar.show(
        context,
        'Video uploaded successfully.',
        type: AppFeedbackType.success,
      );
      context.pop();
    } else {
      setState(() => _uploading = false);
      AppSnackbar.show(
        context,
        provider.actionError ?? 'Upload failed. Please try again.',
        type: AppFeedbackType.error,
      );
    }
  }

  bool _isMp4(String name) => _extension(name).toLowerCase() == '.mp4';

  String _extension(String name) {
    final dot = name.lastIndexOf('.');
    return dot >= 0 ? name.substring(dot) : '.mp4';
  }

  String _mimeType(String name) => _isMp4(name) ? 'video/mp4' : 'video/mp4';

  @override
  Widget build(BuildContext context) {
    final sports = _sports;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Stack(
        children: [
          const Positioned.fill(child: AppAmbientBackground()),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: AppBreakpoints.horizontalPadding(context).add(
                const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              ),
              child: AppBreakpoints.constrain(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SportSelector(
                                sports: sports,
                                selectedSportId: _selectedSportId,
                                enabled: !_uploading,
                                onChanged: (id) =>
                                    setState(() => _selectedSportId = id),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _buildVideoPicker(context),
                              const SizedBox(height: AppSpacing.lg),
                              AppTextField(
                                controller: _title,
                                label: 'Title',
                                hintText: 'e.g. Backhand drill',
                                icon: Icons.title,
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? 'Title is required'
                                        : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                controller: _message,
                                label: 'Message (optional)',
                                hintText: 'Add a note for your coach',
                                icon: Icons.notes,
                                maxLines: 3,
                              ),
                              if (_uploading) ...[
                                const SizedBox(height: AppSpacing.xl),
                                _ProgressBar(progress: _progress),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: _uploading ? 'Uploading...' : 'Upload Video',
                          icon: Icons.cloud_upload_outlined,
                          onPressed: _uploading ? null : _upload,
                          loading: _uploading && !_success,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPicker(BuildContext context) {
    final video = _video;
    if (video == null) {
      return OutlinedButton.icon(
        onPressed: _uploading ? null : _pickVideo,
        icon: const Icon(Icons.video_call_outlined),
        label: const Text('Choose video from gallery'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.br(8)),
        ),
      );
    }

    final sizeMb = _fileSizeBytes / (1024 * 1024);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AuthPalette.bg(context),
        borderRadius: AppRadii.br(AppRadii.medium),
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.movie_outlined, color: AuthPalette.red),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_durationSeconds == null ? 'Duration unavailable' : VideoFormat.duration(_durationSeconds!)} · ${sizeMb.toStringAsFixed(1)} MB',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AuthPalette.subtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _uploading ? null : _pickVideo,
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _SportSelector extends StatelessWidget {
  const _SportSelector({
    required this.sports,
    required this.selectedSportId,
    required this.onChanged,
    this.enabled = true,
  });

  final List<AthleteSportInfo> sports;
  final String? selectedSportId;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (sports.isEmpty) {
      return Text(
        'No sports available. You can still upload without selecting a sport.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AuthPalette.subtitle(context),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedSportId,
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('General'),
        ),
        for (final sport in sports)
          DropdownMenuItem<String>(
            value: sport.sportId,
            child: Text(sport.name),
          ),
      ],
      onChanged: enabled ? (value) => onChanged(value == '' ? null : value) : null,
      decoration: InputDecoration(
        labelText: 'Sport',
        fillColor: AuthPalette.surface(context),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: AuthPalette.border(context)),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Uploading',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AuthPalette.subtitle(context),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AuthPalette.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AuthPalette.border(context),
          ),
        ),
      ],
    );
  }
}
