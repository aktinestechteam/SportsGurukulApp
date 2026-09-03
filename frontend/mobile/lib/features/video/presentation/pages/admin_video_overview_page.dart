import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/app_ambient_background.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../domain/entities/video_submission.dart';
import '../providers/video_provider.dart';

/// Read-only academy admin view of each coach's video workload.
class AdminVideoOverviewPage extends StatefulWidget {
  const AdminVideoOverviewPage({required this.academyId, super.key});

  final String academyId;

  @override
  State<AdminVideoOverviewPage> createState() => _AdminVideoOverviewPageState();
}

class _AdminVideoOverviewPageState extends State<AdminVideoOverviewPage> {
  String? _sport;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<VideoProvider>()
            .loadAdminCoachesOverview(widget.academyId);
      }
    });
  }

  Future<void> _refresh() async {
    await context
        .read<VideoProvider>()
        .loadAdminCoachesOverview(widget.academyId, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final coaches = provider.adminOverview;
    final sports = _uniqueSports(coaches);

    return Scaffold(
      appBar: AppBar(title: const Text('Video Overview')),
      body: Stack(
        children: [
          const Positioned.fill(child: AppAmbientBackground()),
          Positioned.fill(
            child: _buildContent(context, provider, coaches, sports),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    VideoProvider provider,
    List<CoachVideoOverview> coaches,
    List<String> sports,
  ) {
    if (provider.isLoadingAdminOverview) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AppLoading(label: 'Loading coaches...'),
      );
    }

    if (provider.adminOverviewStatus == VideoStatus.error) {
      return AppErrorState(
        title: 'Could not load video overview',
        message: provider.adminOverviewError,
        onRetry: () => context
            .read<VideoProvider>()
            .loadAdminCoachesOverview(widget.academyId),
      );
    }

    if (coaches.isEmpty) {
      return AppEmptyState(
        icon: Icons.sports,
        title: 'No coaches yet',
        subtitle:
            'Coaches must be added to this academy before their videos can be reviewed.',
      );
    }

    final filtered = _filterBySport(coaches, _sport);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: AppBreakpoints.horizontalPadding(context).add(
              const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xxl),
            ),
            sliver: SliverToBoxAdapter(
              child: AppBreakpoints.constrain(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSectionHeader(
                      title: 'Coaches',
                      subtitle:
                          '${filtered.length} ${filtered.length == 1 ? 'coach' : 'coaches'} · videos and unreviewed counts',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        initialValue: _sport ?? '',
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('All sports'),
                          ),
                          for (final sport in sports)
                            DropdownMenuItem<String>(
                              value: sport,
                              child: Text(sport, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sport = (value == null || value.isEmpty)
                                ? null
                                : value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Sport',
                          prefixIcon: const Icon(Icons.sports_outlined, size: 20),
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
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                        child: AppEmptyState(
                          icon: Icons.filter_alt_off_outlined,
                          title: 'No coaches for this sport',
                          subtitle:
                              'Try clearing the sport filter to see everyone.',
                        ),
                      )
                    else
                      for (final coach in filtered) ...[
                        _CoachCard(
                          coach: coach,
                          onView: () => _openCoach(coach),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCoach(CoachVideoOverview coach) {
    context.push(
      '/admin/academies/${widget.academyId}/videos/${coach.coachId}',
      extra: coach.fullName,
    );
  }

  List<String> _uniqueSports(List<CoachVideoOverview> coaches) {
    final seen = <String>{};
    final result = <String>[];
    for (final coach in coaches) {
      for (final sport in coach.sports) {
        if (sport.isEmpty || seen.contains(sport)) continue;
        seen.add(sport);
        result.add(sport);
      }
    }
    return result;
  }

  List<CoachVideoOverview> _filterBySport(
    List<CoachVideoOverview> coaches,
    String? sport,
  ) {
    if (sport == null || sport.isEmpty) {
      return coaches;
    }
    return coaches
        .where((c) => c.sports.contains(sport))
        .toList();
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.coach, required this.onView});

  final CoachVideoOverview coach;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AuthPalette.surface(context),
        borderRadius: AppRadii.br(AppRadii.medium),
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AuthPalette.red.withValues(alpha: 0.1),
                child: Text(
                  _initials(coach.fullName),
                  style: const TextStyle(
                    color: AuthPalette.red,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (coach.sports.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        coach.sports.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AuthPalette.subtitle(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (coach.sports.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final sport in coach.sports)
                  AppBadge(
                    label: sport,
                    icon: Icons.sports_outlined,
                    compact: true,
                    backgroundColor: AuthPalette.bg(context),
                    foregroundColor: AuthPalette.textPrimary(context),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: AuthPalette.divider(context)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatPill(
                icon: Icons.groups_outlined,
                label: '${coach.athleteCount} athletes',
                color: AuthPalette.red,
              ),
              _StatPill(
                icon: Icons.video_library_outlined,
                label: '${coach.totalVideoCount} videos',
                color: AuthPalette.textPrimary(context),
              ),
              if (coach.unreviewedVideoCount > 0)
                _StatPill(
                  icon: Icons.pending_outlined,
                  label: '${coach.unreviewedVideoCount} unreviewed',
                  color: const Color(0xFFE65100),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'View',
              icon: Icons.visibility_outlined,
              onPressed: onView,
              expanded: false,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.br(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}