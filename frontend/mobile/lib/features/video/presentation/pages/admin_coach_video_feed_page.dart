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
import '../../domain/entities/video_submission.dart';
import '../providers/video_provider.dart';
import '../widgets/video_format.dart';

/// Read-only academy admin view of a single coach's athlete videos.
class AdminCoachVideoFeedPage extends StatefulWidget {
  const AdminCoachVideoFeedPage({
    required this.academyId,
    required this.coachId,
    this.coachName = '',
    super.key,
  });

  final String academyId;
  final String coachId;
  final String coachName;

  @override
  State<AdminCoachVideoFeedPage> createState() =>
      _AdminCoachVideoFeedPageState();
}

class _AdminCoachVideoFeedPageState extends State<AdminCoachVideoFeedPage> {
  String? _athleteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VideoProvider>().loadAdminCoachFeed(
          widget.academyId,
          widget.coachId,
        );
      }
    });
  }

  Future<void> _refresh() async {
    await context.read<VideoProvider>().loadAdminCoachFeed(
      widget.academyId,
      widget.coachId,
      athleteId: _athleteId,
      refresh: true,
    );
  }

  void _applyAthleteFilter(String? athleteId) {
    setState(() => _athleteId = athleteId);
    context.read<VideoProvider>().loadAdminCoachFeed(
      widget.academyId,
      widget.coachId,
      athleteId: athleteId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final videos = provider.adminFeed;
    final athletes = _uniqueAthletes(videos);
    final title = widget.coachName.trim().isEmpty
        ? 'Coach Videos'
        : widget.coachName.trim();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.visibility_outlined, size: 20, color: AuthPalette.red),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AppAmbientBackground()),
          Positioned.fill(
            child: _buildContent(context, provider, videos, athletes),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    VideoProvider provider,
    List<VideoSubmission> videos,
    List<_FilterItem> athletes,
  ) {
    if (provider.isLoadingAdminFeed) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AppLoading(label: 'Loading videos...'),
      );
    }

    if (provider.adminFeedStatus == VideoStatus.error) {
      return AppErrorState(
        title: 'Could not load videos',
        message: provider.adminFeedError,
        onRetry: () => context.read<VideoProvider>().loadAdminCoachFeed(
          widget.academyId,
          widget.coachId,
          athleteId: _athleteId,
        ),
      );
    }

    if (videos.isEmpty) {
      return AppEmptyState(
        icon: Icons.video_library_outlined,
        title: 'No videos yet',
        subtitle:
            'This coach has not received any video submissions yet.',
      );
    }

    final groups = _groupByDate(videos);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppBreakpoints.horizontalPadding(context).add(
          const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xxl),
        ),
        child: AppBreakpoints.constrain(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionHeader(
                title: 'Athlete videos',
                subtitle:
                    '${videos.length} ${videos.length == 1 ? 'video' : 'videos'} · read only',
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _athleteId ?? '',
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('All athletes'),
                  ),
                  for (final item in athletes)
                    DropdownMenuItem<String>(
                      value: item.value ?? item.label,
                      child: Text(item.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => _applyAthleteFilter(
                  value == null || value.isEmpty ? null : value,
                ),
                decoration: InputDecoration(
                  labelText: 'Athlete',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  filled: true,
                  fillColor: AuthPalette.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AuthPalette.border(context)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: AppEmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'No videos for this athlete',
                    subtitle: 'Try clearing the filter to see all videos.',
                  ),
                )
              else
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
                    _AdminVideoCard(
                      video: video,
                      onTap: () => _openVideo(video),
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

  void _openVideo(VideoSubmission video) {
    context.push(
      '/admin/academies/${widget.academyId}/videos/${widget.coachId}/${video.id}',
      extra: widget.coachName,
    );
  }

  List<_FilterItem> _uniqueAthletes(List<VideoSubmission> videos) {
    final seen = <String>{};
    final result = <_FilterItem>[];
    for (final v in videos) {
      final id = v.athleteId;
      if (id == null || id.isEmpty || v.athleteName.isEmpty) continue;
      if (seen.contains(id)) continue;
      seen.add(id);
      result.add(_FilterItem(v.athleteName, id));
    }
    return result;
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
      groups
          .putIfAbsent(VideoFormat.groupLabel(date), () => [])
          .add(video);
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

class _FilterItem {
  const _FilterItem(this.label, this.value);

  final String label;
  final String? value;
}

class _VideoGroup {
  const _VideoGroup(this.label, this.videos);

  final String label;
  final List<VideoSubmission> videos;
}

class _AdminVideoCard extends StatelessWidget {
  const _AdminVideoCard({required this.video, required this.onTap});

  final VideoSubmission video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = VideoFormat.parseDate(video.createdAt);

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
            _Thumbnail(video: video),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 16, color: AuthPalette.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          video.athleteName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AuthPalette.red,
                              ),
                        ),
                      ),
                      Text(
                        VideoFormat.timeAgo(date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AuthPalette.muted(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (video.sportName != null && video.sportName!.isNotEmpty)
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