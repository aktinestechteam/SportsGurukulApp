import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/app_ambient_background.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/video_submission.dart';
import '../providers/video_provider.dart';
import '../widgets/video_format.dart';

class AthleteVideosPage extends StatefulWidget {
  const AthleteVideosPage({super.key});

  @override
  State<AthleteVideosPage> createState() => _AthleteVideosPageState();
}

class _AthleteVideosPageState extends State<AthleteVideosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VideoProvider>().loadMyVideos();
      }
    });
  }

  Future<void> _refresh() async {
    await context.read<VideoProvider>().loadMyVideos(refresh: true);
  }

  void _openUpload() => context.push('/athlete/videos/upload');

  void _openVideo(VideoSubmission video) =>
      context.push('/athlete/videos/${video.id}');

  Future<void> _confirmDelete(VideoSubmission video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete video?'),
        content: Text(
          'This will permanently remove "${video.title}" along with all of its '
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
    final ok = await provider.deleteVideo(video.id);
    if (!mounted) {
      return;
    }
    AppSnackbar.show(
      context,
      ok ? 'Video deleted.' : provider.actionError ?? 'Could not delete the video.',
      type: ok ? AppFeedbackType.success : AppFeedbackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final videos = provider.myVideos;

    return Scaffold(
      appBar: AppBar(title: const Text('My Videos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUpload,
        backgroundColor: AuthPalette.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.videocam_outlined),
        label: const Text('Upload'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AppAmbientBackground()),
          Positioned.fill(
            child: _buildContent(context, provider, videos),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    VideoProvider provider,
    List<VideoSubmission> videos,
  ) {
    if (provider.isLoadingMyVideos) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AppLoading(label: 'Loading your videos...'),
      );
    }

    if (provider.myVideosStatus == VideoStatus.error) {
      return AppErrorState(
        title: 'Could not load videos',
        message: provider.myVideosError,
        onRetry: () => context.read<VideoProvider>().loadMyVideos(),
      );
    }

    if (videos.isEmpty) {
      return AppEmptyState(
        icon: Icons.video_library_outlined,
        title: 'No videos yet',
        subtitle: 'Share your training clips with your coach.',
        actionLabel: 'Upload a video',
        onAction: _openUpload,
      );
    }

    final groups = _groupByDate(videos);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppBreakpoints.horizontalPadding(context).add(
          const EdgeInsets.only(top: AppSpacing.lg, bottom: 120),
        ),
        child: AppBreakpoints.constrain(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionHeader(
                title: 'Your videos',
                subtitle:
                    '${videos.length} ${videos.length == 1 ? 'video' : 'videos'} shared with your coach',
              ),
              for (final group in groups) ...[
                Text(
                  group.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AuthPalette.red,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final video in group.videos) ...[
                  _VideoCard(
                    video: video,
                    onTap: () => _openVideo(video),
                    onDelete: () => _confirmDelete(video),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_VideoGroup> _groupByDate(List<VideoSubmission> videos) {
    final ordered = [...videos]
      ..sort((a, b) {
        final da = VideoFormat.parseDate(a.createdAt);
        final db = VideoFormat.parseDate(b.createdAt);
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });

    final groups = <String, List<VideoSubmission>>{};
    for (final video in ordered) {
      final date = VideoFormat.parseDate(video.createdAt) ?? DateTime.now();
      groups.putIfAbsent(
        VideoFormat.groupLabel(date),
        () => [],
      ).add(video);
    }

    const order = ['Today', 'Yesterday', 'Older'];
    final result = <_VideoGroup>[];
    for (final label in order) {
      if (groups.containsKey(label)) {
        result.add(_VideoGroup(label, groups[label]!));
      }
    }
    return result;
  }
}

class _VideoGroup {
  const _VideoGroup(this.label, this.videos);

  final String label;
  final List<VideoSubmission> videos;
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video, required this.onTap, this.onDelete});

  final VideoSubmission video;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final date = VideoFormat.parseDate(video.createdAt) ?? DateTime.now();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AuthPalette.surface(context),
          borderRadius: AppRadii.br(AppRadii.medium),
          border: Border.all(color: AuthPalette.border(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                _Thumbnail(video: video),
                if (onDelete != null)
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (video.sportName != null &&
                                video.sportName!.isNotEmpty)
                              AppBadge(
                                label: video.sportName!,
                                icon: Icons.sports_outlined,
                                compact: true,
                              ),
                            AppBadge(
                              label: VideoFormat.duration(video.durationSeconds),
                              icon: Icons.schedule,
                              compact: true,
                            ),
                            AppBadge(
                              label: '${video.commentCount}',
                              icon: Icons.chat_bubble_outline,
                              compact: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        VideoFormat.dateLabel(date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AuthPalette.subtitle(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.video});

  final VideoSubmission video;

  @override
  Widget build(BuildContext context) {
    final url = video.thumbnailUrl;
    final hasUrl = url != null && url.isNotEmpty;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: hasUrl
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.network(url, fit: BoxFit.cover),
                const _PlayOverlay(),
              ],
            )
          : Container(
              color: AuthPalette.darkSurface,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Center(
                    child: Icon(
                      Icons.videocam_outlined,
                      size: 42,
                      color: Colors.white38,
                    ),
                  ),
                  const _PlayOverlay(),
                ],
              ),
            ),
    );
  }
}

class _PlayOverlay extends StatelessWidget {
  const _PlayOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
      ),
    );
  }
}
