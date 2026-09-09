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

class CoachVideoFeedPage extends StatefulWidget {
  const CoachVideoFeedPage({super.key});

  @override
  State<CoachVideoFeedPage> createState() => _CoachVideoFeedPageState();
}

class _CoachVideoFeedPageState extends State<CoachVideoFeedPage> {
  String? _sportId;
  String? _athleteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final provider = context.read<VideoProvider>();
      provider.loadFeed();
      provider.loadUnreadCount();
    });
  }

  Future<void> _refresh() async {
    final provider = context.read<VideoProvider>();
    await Future.wait([
      provider.loadFeed(
        sportId: _sportId,
        athleteId: _athleteId,
        refresh: true,
      ),
      provider.loadUnreadCount(),
    ]);
  }

  void _applyFilters({String? sportId, String? athleteId}) {
    setState(() {
      _sportId = sportId;
      _athleteId = athleteId;
    });
    context.read<VideoProvider>().loadFeed(
      sportId: sportId,
      athleteId: athleteId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final videos = provider.feed;
    final sports = _uniqueSports(videos);
    final athletes = _uniqueAthletes(videos);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _openNotifications(context),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (provider.unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: const BoxDecoration(
                        color: AuthPalette.red,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        provider.unreadCount > 99
                            ? '99+'
                            : '${provider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AppAmbientBackground()),
          Positioned.fill(
            child: _buildContent(
              context,
              provider,
              videos,
              sports: sports,
              athletes: athletes,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    VideoProvider provider,
    List<VideoSubmission> videos, {
    required List<_FilterItem> sports,
    required List<_FilterItem> athletes,
  }) {
    if (provider.isLoadingFeed) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AppLoading(label: 'Loading videos...'),
      );
    }

    if (provider.feedStatus == VideoStatus.error) {
      return AppErrorState(
        title: 'Could not load videos',
        message: provider.feedError,
        onRetry: () => context.read<VideoProvider>().loadFeed(
          sportId: _sportId,
          athleteId: _athleteId,
        ),
      );
    }

    if (videos.isEmpty) {
      return AppEmptyState(
        icon: Icons.video_library_outlined,
        title: 'No videos yet',
        subtitle:
            'Videos shared by your athletes will appear here as soon as they upload.',
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
                title: 'Coach feed',
                subtitle:
                    '${videos.length} ${videos.length == 1 ? 'video' : 'videos'} from your athletes',
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _FilterDropdown(
                      label: 'Sport',
                      icon: Icons.sports_outlined,
                      items: sports,
                      value: _sportId,
                      hint: 'All sports',
                      onChanged: (id) => _applyFilters(
                        sportId: id,
                        athleteId: _athleteId,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _FilterDropdown(
                      label: 'Athlete',
                      icon: Icons.person_outline,
                      items: athletes,
                      value: _athleteId,
                      hint: 'All athletes',
                      onChanged: (id) => _applyFilters(
                        sportId: _sportId,
                        athleteId: id,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
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
                  _VideoCard(video: video, onTap: () => _openVideo(video)),
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

  void _openVideo(VideoSubmission video) =>
      context.push('/coach/videos/${video.id}');

  List<_FilterItem> _uniqueSports(List<VideoSubmission> videos) {
    final seen = <String>{};
    final result = <_FilterItem>[];
    for (final v in videos) {
      final id = v.sportId;
      final name = v.sportName;
      if (id == null || id.isEmpty || name == null || name.isEmpty) continue;
      if (seen.contains(id)) continue;
      seen.add(id);
      result.add(_FilterItem(name, id));
    }
    return result;
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

  void _openNotifications(BuildContext context) {
    final provider = context.read<VideoProvider>();
    provider.loadNotifications();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (context) => const _NotificationsSheet(),
    );
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

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final List<_FilterItem> items;
  final String? value;
  final String hint;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: [
        DropdownMenuItem<String>(
          value: '',
          child: Text(hint, overflow: TextOverflow.ellipsis),
        ),
        for (final item in items)
          DropdownMenuItem<String>(
            value: item.value ?? item.label,
            child: Text(item.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => onChanged(v == null || v.isEmpty ? null : v),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
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
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video, required this.onTap});

  final VideoSubmission video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isNew = video.isNew || !video.isViewed;
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
            Stack(
              children: [
                _Thumbnail(video: video),
                if (isNew)
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AuthPalette.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
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

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final notifications = provider.notifications;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Text(
                    'No notifications yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AuthPalette.subtitle(context),
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: AuthPalette.divider(context)),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.video_library_outlined,
                        color: AuthPalette.red,
                      ),
                      title: Text(
                        n.videoTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${n.actorName} · ${VideoFormat.timeAgoString(n.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AuthPalette.subtitle(context),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/coach/videos/${n.videoId}');
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
