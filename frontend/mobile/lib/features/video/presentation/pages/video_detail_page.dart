import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/app_ambient_background.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/video_comment.dart';
import '../../domain/entities/video_submission.dart';
import '../../domain/repositories/video_repository.dart';
import '../providers/video_provider.dart';
import '../widgets/video_format.dart';
import '../widgets/voice_note_recorder.dart';

enum VideoRole { athlete, coach, admin }

class VideoDetailPage extends StatefulWidget {
  const VideoDetailPage({
    required this.videoId,
    this.role = VideoRole.athlete,
    this.adminCoachName,
    super.key,
  });

  final String videoId;
  final VideoRole role;

  /// Coach being reviewed when [role] is [VideoRole.admin].
  final String? adminCoachName;

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  final _messageController = TextEditingController();

  Player? _player;
  VideoController? _videoController;
  bool _playerReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VideoProvider>().openVideo(widget.videoId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _player?.dispose();
    context.read<VideoProvider>().closeVideo();
    super.dispose();
  }

  void _initPlayer(VideoDetail video) {
    final url = video.videoUrl;
    if (url.isEmpty) {
      return;
    }
    if (_player != null && _playerReady) {
      return;
    }
    try {
      final player = Player();
      final controller = VideoController(player);
      _videoController = controller;
      _player = player;
      player.open(Media(url)).then((_) {
        if (mounted) {
          setState(() => _playerReady = true);
          player.setVolume(100.0);
        }
      }).catchError((_) {
        if (mounted) {
          setState(() => _playerReady = false);
        }
      });
    } catch (_) {
      // Player init failures are non-fatal to the screen.
    }
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _messageController.clear();
    final comment = await context
        .read<VideoProvider>()
        .addComment(widget.videoId, AddCommentInput(message: text));
    if (comment == null && mounted) {
      AppSnackbar.show(
        context,
        context.read<VideoProvider>().actionError ?? 'Could not send message.',
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _recordVoiceNote() async {
    final result = await VoiceNoteRecorder.show(context);
    if (result == null || !mounted) {
      return;
    }
    await context.read<VideoProvider>().addComment(
      widget.videoId,
      AddCommentInput(
        voiceNoteS3Key: result.s3Key,
        voiceNoteDurationSeconds: result.durationSeconds,
        voiceNoteSizeBytes: result.sizeBytes,
      ),
    );
  }

  Future<void> _editComment(VideoComment comment, String message) async {
    final updated = await context.read<VideoProvider>().editComment(
      widget.videoId,
      comment.id,
      message,
    );
    if (updated == null && mounted) {
      AppSnackbar.show(
        context,
        context.read<VideoProvider>().actionError ?? 'Could not update comment.',
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _confirmDeleteComment(VideoComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This comment will be removed for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AuthPalette.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final ok = await context.read<VideoProvider>().deleteComment(
      widget.videoId,
      comment.id,
    );
    if (!ok && mounted) {
      AppSnackbar.show(
        context,
        context.read<VideoProvider>().actionError ?? 'Could not delete comment.',
        type: AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final video = provider.currentVideo;

    if (provider.isLoadingDetail) {
      return _pageScaffold(
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: AppLoading(label: 'Loading video...'),
        ),
      );
    }
    if (video == null) {
      return _pageScaffold(
        child: AppErrorState(
          title: 'Could not load video',
          message: provider.detailError,
          onRetry: () => context.read<VideoProvider>().openVideo(widget.videoId),
        ),
      );
    }

    _initPlayer(video);

    final isAdmin = widget.role == VideoRole.admin;

    return _pageScaffold(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _VideoPlayer(
                  controller: _videoController,
                  ready: _playerReady,
                ),
                _VideoInfo(video: video),
                Divider(height: 1, color: AuthPalette.divider(context)),
                const _CommentsHeader(),
                if (provider.comments.isEmpty)
                  const _EmptyComments()
                else
                  for (final comment in provider.comments)
                    _CommentBubble(
                      comment: comment,
                      role: widget.role,
                      onEdit: (message) => _editComment(comment, message),
                      onDelete: () => _confirmDeleteComment(comment),
                    ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
          if (!isAdmin)
            _InputBar(
              controller: _messageController,
              onSend: _sendText,
              onMic: _recordVoiceNote,
            ),
        ],
      ),
    );
  }

  Widget _pageScaffold({required Widget child}) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video'),
        actions: [
          if (widget.role == VideoRole.athlete) ...[
            IconButton(
              tooltip: 'Delete video',
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDeleteVideo,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AppAmbientBackground()),
          Positioned.fill(
            child: Column(
              children: [
                if (widget.role == VideoRole.admin)
                  _ReadOnlyBanner(coachName: widget.adminCoachName ?? ''),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteVideo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete video?'),
        content: const Text(
          'This will permanently remove the video along with all of its '
          'comments. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AuthPalette.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<VideoProvider>();
    final ok = await provider.deleteVideo(widget.videoId);
    if (!mounted) {
      return;
    }
    AppSnackbar.show(
      context,
      ok ? 'Video deleted.' : provider.actionError ?? 'Could not delete the video.',
      type: ok ? AppFeedbackType.success : AppFeedbackType.error,
    );
    if (ok) {
      Navigator.of(context).pop();
    }
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner({required this.coachName});

  final String coachName;

  @override
  Widget build(BuildContext context) {
    final coach = coachName.trim();
    return Container(
      width: double.infinity,
      color: AuthPalette.surface(context),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.visibility_outlined, size: 18, color: AuthPalette.red),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                coach.isEmpty
                    ? 'Viewing — Read Only'
                    : 'Viewing as $coach — Read Only',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AuthPalette.subtitle(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayer extends StatefulWidget {
  const _VideoPlayer({
    required this.controller,
    required this.ready,
  });

  final VideoController? controller;
  final bool ready;

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: (controller != null && widget.ready)
            ? Video(
                controller: controller,
                controls: (state) => _VideoControls(state: state),
                fit: BoxFit.contain,
                wakelock: true,
              )
            : const Center(
                child: Icon(
                  Icons.videocam_outlined,
                  size: 48,
                  color: Colors.white38,
                ),
              ),
      ),
    );
  }
}

class _VideoControls extends StatefulWidget {
  const _VideoControls({required this.state});

  final VideoState state;

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls>
    with SingleTickerProviderStateMixin {
  late final Player _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _buffering = false;
  bool _dragging = false;
  double _dragValue = 0;

  bool _visible = true;
  Timer? _hideTimer;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _player = widget.state.widget.controller.player;
    _position = _player.state.position;
    _duration = _player.state.duration;
    _playing = _player.state.playing;
    _subscriptions.addAll([
      _player.stream.position.listen((d) {
        if (mounted) {
          setState(() => _position = d);
        }
      }),
      _player.stream.duration.listen((d) {
        if (mounted) {
          setState(() => _duration = d);
        }
      }),
      _player.stream.playing.listen((p) {
        if (mounted) {
          setState(() => _playing = p);
          if (p) _scheduleHide();
        }
      }),
      _player.stream.buffering.listen((b) {
        if (mounted) {
          setState(() => _buffering = b);
        }
      }),
      _player.stream.completed.listen((done) {
        if (mounted && done) {
          setState(() {
            _position = Duration.zero;
            _visible = true;
          });
          _fadeController.forward();
          _cancelHide();
        }
      }),
    ]);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeController.dispose();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  void _toggleVisibility() {
    setState(() {
      _visible = !_visible;
    });
    if (_visible) {
      _fadeController.forward();
      _scheduleHide();
    } else {
      _fadeController.reverse();
      _cancelHide();
    }
  }

  void _scheduleHide() {
    _cancelHide();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _playing) {
        setState(() => _visible = false);
        _fadeController.reverse();
      }
    });
  }

  void _cancelHide() {
    _hideTimer?.cancel();
  }

  void _onInteraction() {
    if (_visible) {
      _scheduleHide();
    } else {
      _toggleVisibility();
    }
  }

  Duration get _maxDuration =>
      _duration > Duration.zero ? _duration : Duration.zero;

  void _seekBy(int seconds) {
    var target = _position + Duration(seconds: seconds);
    if (target < Duration.zero) {
      target = Duration.zero;
    }
    final duration = _maxDuration;
    if (duration > Duration.zero && target > duration) {
      target = duration;
    }
    setState(() => _position = target);
    _player.seek(target);
    _scheduleHide();
  }

  void _onSeekChanged(double value) {
    setState(() {
      _dragging = true;
      _dragValue = value;
    });
  }

  void _onSeekEnd(double value) {
    final duration = _maxDuration;
    final target = duration.inMilliseconds == 0
        ? Duration.zero
        : Duration(milliseconds: value.round());
    _dragging = false;
    setState(() => _position = target);
    _player.seek(target);
    _scheduleHide();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  double get _displayMs {
    if (_dragging) return _dragValue;
    return _position.inMilliseconds.toDouble();
  }

  double get _sliderMax {
    final ms = _maxDuration.inMilliseconds.toDouble();
    return ms > 0 ? ms : 1;
  }

  @override
  Widget build(BuildContext context) {
    final white = Colors.white;
    return GestureDetector(
      onTap: _onInteraction,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_buffering)
              const Center(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
            FadeTransition(
              opacity: _fadeAnimation,
              child: IgnorePointer(
                ignoring: !_visible,
                child: Column(
                  children: [
                    const Spacer(),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ControlButton(
                            tooltip: 'Back 10 seconds',
                            icon: Icons.replay_10,
                            color: white,
                            onPressed: () => _seekBy(-10),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: _playing ? 'Pause' : 'Play',
                            onPressed: () {
                              _player.playOrPause();
                              _scheduleHide();
                            },
                            iconSize: 72,
                            color: white,
                            icon: Icon(
                              _playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              size: 72,
                              color: white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _ControlButton(
                            tooltip: 'Forward 10 seconds',
                            icon: Icons.forward_10,
                            color: white,
                            onPressed: () => _seekBy(10),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              activeTrackColor: Colors.redAccent,
                              inactiveTrackColor: Colors.white30,
                              thumbColor: Colors.redAccent,
                              overlayShape: SliderComponentShape.noOverlay,
                            ),
                            child: Slider(
                              min: 0,
                              max: _sliderMax,
                              value: _displayMs.clamp(0.0, _sliderMax),
                              onChangeStart: (_) =>
                                  setState(() => _dragging = true),
                              onChanged: _onSeekChanged,
                              onChangeEnd: _onSeekEnd,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Text(
                                  _fmt(_position),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _fmt(_maxDuration),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _ControlButton(
                                  tooltip: widget.state.isFullscreen()
                                      ? 'Exit fullscreen'
                                      : 'Enter fullscreen',
                                  icon: widget.state.isFullscreen()
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  color: white,
                                  onPressed: () => widget.state.isFullscreen()
                                      ? widget.state.exitFullscreen()
                                      : widget.state.enterFullscreen(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: color,
      iconSize: 32,
      icon: Icon(icon, color: color),
    );
  }
}

class _VideoInfo extends StatelessWidget {
  const _VideoInfo({required this.video});

  final VideoDetail video;

  @override
  Widget build(BuildContext context) {
    final date = VideoFormat.parseDate(video.createdAt);

    return Padding(
      padding: AppBreakpoints.horizontalPadding(context).add(
        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              video.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (video.sportName != null && video.sportName!.isNotEmpty)
                  _MetaChip(
                    icon: Icons.sports_outlined,
                    label: video.sportName!,
                  ),
                _MetaChip(
                  icon: Icons.schedule,
                  label: VideoFormat.duration(video.durationSeconds),
                ),
                if (date != null)
                  _MetaChip(
                    icon: Icons.calendar_today_outlined,
                    label: VideoFormat.dateLabel(date),
                  ),
              ],
            ),
            if (video.message != null && video.message!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                video.message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AuthPalette.textPrimary(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: AuthPalette.surface(context),
        borderRadius: AppRadii.br(AppRadii.pill),
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AuthPalette.red),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AuthPalette.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentsHeader extends StatelessWidget {
  const _CommentsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Text(
        'Comments',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, vertical: AppSpacing.lg,
      ),
      child: Center(
        child: Text(
          'No comments yet. Say hello to your coach!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AuthPalette.subtitle(context),
          ),
        ),
      ),
    );
  }
}

class _CommentBubble extends StatefulWidget {
  const _CommentBubble({
    required this.comment,
    required this.role,
    required this.onEdit,
    required this.onDelete,
  });

  final VideoComment comment;
  final VideoRole role;
  final ValueChanged<String> onEdit;
  final VoidCallback onDelete;

  @override
  State<_CommentBubble> createState() => _CommentBubbleState();
}

class _CommentBubbleState extends State<_CommentBubble> {
  late bool _editing;
  late final TextEditingController _editController;

  _CommentBubbleState();

  @override
  void initState() {
    super.initState();
    _editing = false;
    _editController = TextEditingController(text: widget.comment.message ?? '');
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEditing() {
    _editController.text = widget.comment.message ?? '';
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    setState(() => _editing = false);
  }

  void _saveEditing() {
    final text = _editController.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _editing = false);
    widget.onEdit(text);
  }

  VideoComment get comment => widget.comment;

  @override
  Widget build(BuildContext context) {
    final isOwn = comment.isOwnComment;
    final showActions = isOwn && !_editing;

    final bubbleColor = isDeleted()
        ? AuthPalette.border(context).withValues(alpha: 0.4)
        : _bubbleColor(context, isOwn);

    final textColor = isDeleted()
        ? AuthPalette.subtitle(context)
        : AuthPalette.textPrimary(context);

    final Widget body = isDeleted()
        ? Text(
            'This comment was deleted',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontStyle: FontStyle.italic,
            ),
          )
        : _editing
            ? _EditBubbleContent(
                controller: _editController,
                isOwn: isOwn,
                onCancel: _cancelEditing,
                onSave: _saveEditing,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (comment.hasVoiceNote) ...[
                    _VoiceNoteBubble(comment: comment),
                  ],
                  if (comment.message != null && comment.message!.isNotEmpty)
                    Text(
                      comment.message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                    ),
                  if (showActions) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          visualDensity: VisualDensity.compact,
                          onPressed: _startEditing,
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: AuthPalette.muted(context)),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          visualDensity: VisualDensity.compact,
                          onPressed: widget.onDelete,
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: AuthPalette.red),
                        ),
                      ],
                    ),
                  ],
                ],
              );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment:
            isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isDeleted()) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs, right: AppSpacing.xs, bottom: 4,
              ),
              child: Text(
                comment.authorName.isEmpty ? _authorFallback(isOwn) : comment.authorName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AuthPalette.subtitle(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isOwn
                  ? MediaQuery.of(context).size.width * 0.84
                  : MediaQuery.of(context).size.width * 0.8,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadii.medium),
                  topRight: const Radius.circular(AppRadii.medium),
                  bottomLeft: Radius.circular(isOwn ? AppRadii.medium : 2),
                  bottomRight: Radius.circular(isOwn ? 2 : AppRadii.medium),
                ),
              ),
              child: body,
            ),
          ),
        ],
      ),
    );
  }

  Color _bubbleColor(BuildContext context, bool isOwn) {
    if (isOwn) {
      return const Color(0xFF1565C0).withValues(alpha: 0.12);
    }
    if (widget.role == VideoRole.coach || widget.role == VideoRole.admin) {
      final isCoachAuthor = (comment.authorRole ?? '').toLowerCase() == 'coach';
      return isCoachAuthor
          ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
          : const Color(0xFF1565C0).withValues(alpha: 0.12);
    }
    return const Color(0xFF2E7D32).withValues(alpha: 0.12);
  }

  String _authorFallback(bool isOwn) {
    if (isOwn) return 'You';
    if ((widget.role == VideoRole.coach || widget.role == VideoRole.admin) &&
        (comment.authorRole ?? '').toLowerCase() == 'coach') {
      return 'Coach';
    }
    return 'Athlete';
  }

  bool isDeleted() => comment.isDeleted;
}

class _VoiceNoteBubble extends StatefulWidget {
  const _VoiceNoteBubble({required this.comment});

  final VideoComment comment;

  @override
  State<_VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<_VoiceNoteBubble> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool _loading = false;
  bool _error = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _awaitingInit = false;

  @override
  void initState() {
    super.initState();
    _awaitingInit = true;
    _subscriptions.addAll([
      _player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() {
          _loading = state.processingState == ProcessingState.loading;
          _playing = state.playing;
        });
        if (state.processingState == ProcessingState.completed) {
          _player.seek(Duration.zero);
        }
      }),
      _player.positionStream.listen((position) {
        if (!mounted) return;
        setState(() => _position = position);
      }),
      _player.durationStream.listen((duration) {
        if (!mounted) return;
        setState(() => _duration = duration);
      }),
    ]);
    _init();
  }

  Future<void> _init() async {
    final url = widget.comment.voiceNoteUrl;
    if (url == null || url.isEmpty) {
      if (mounted) {
        setState(() {
          _error = true;
          _awaitingInit = false;
        });
      }
      return;
    }
    try {
      await _player.setUrl(url);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _awaitingInit = false;
      });
    } finally {
      if (mounted) {
        setState(() => _awaitingInit = false);
      }
    }
  }

  Future<void> _toggle() async {
    if (_loading) return;
    try {
      if (_playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = true);
      }
    }
  }

  Future<void> _seekTo(double value) async {
    try {
      await _player.seek(Duration(milliseconds: value.round()));
    } catch (_) {
      // Ignore seek errors; playback is unaffected.
    }
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_awaitingInit) {
      return const SizedBox(
        width: 120,
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    if (_error) {
      return const Text(
        'Voice note unavailable',
        style: TextStyle(color: AuthPalette.red, fontSize: 12.5),
      );
    }

    final duration = _duration ?? Duration(seconds: widget.comment.voiceNoteDurationSeconds ?? 0);
    final maxMs = duration.inMilliseconds.clamp(0, 1 << 30).toDouble();
    final value = _position.inMilliseconds
        .clamp(0.0, maxMs > 0 ? maxMs : 1)
        .toDouble();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WaveformPlaceholder(),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 96,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: AuthPalette.red,
              inactiveTrackColor: AuthPalette.divider(context),
              thumbColor: AuthPalette.red,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              min: 0,
              max: maxMs > 0 ? maxMs : 1,
              value: value,
              onChanged: (v) {
                setState(
                  () => _position = Duration(milliseconds: v.round()),
                );
              },
              onChangeEnd: _seekTo,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          VideoFormat.duration(
            _playing || _position > Duration.zero
                ? duration.inSeconds - _position.inSeconds
                : duration.inSeconds,
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AuthPalette.muted(context),
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        IconButton(
          onPressed: _toggle,
          icon: Icon(
            _loading
                ? Icons.hourglass_top
                : _playing
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
            color: AuthPalette.red,
            size: 26,
          ),
          tooltip: _playing ? 'Pause voice note' : 'Play voice note',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _EditBubbleContent extends StatelessWidget {
  const _EditBubbleContent({
    required this.controller,
    required this.isOwn,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool isOwn;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSave(),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 8,
            ),
            filled: true,
            fillColor: AuthPalette.surface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AuthPalette.border(context)),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment:
              isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: AppSpacing.xs),
            FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(backgroundColor: AuthPalette.red),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}

class _WaveformPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bars = [6.0, 10.0, 7.0, 12.0, 8.0, 11.0, 5.0, 9.0, 6.0, 12.0, 8.0, 10.0];
    return SizedBox(
      height: 24,
      width: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final h in bars)
            Container(
              width: 3,
              height: h,
              decoration: BoxDecoration(
                color: AuthPalette.muted(context).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onMic,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final sending = provider.isSendingComment;

    return Container(
      decoration: BoxDecoration(
        color: AuthPalette.surface(context),
        border: Border(top: BorderSide(color: AuthPalette.divider(context))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: sending ? null : onMic,
                icon: const Icon(Icons.mic_none),
                tooltip: 'Record voice note',
                color: AuthPalette.red,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !sending,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 10,
                    ),
                    filled: true,
                    fillColor: AuthPalette.bg(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AuthPalette.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AuthPalette.border(context)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                tooltip: 'Send',
                color: AuthPalette.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
