import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/academy.dart';
import '../providers/academy_provider.dart';

/// Sample statistics rendered on academy cards. Hardcoded placeholders until
/// the data model exposes real counts. Coach and athlete counts are live from
/// the API.
const int _placeholderAchievements = 24;
const int _placeholderEstYear = 2020;

class MyAcademiesSection extends StatelessWidget {
  const MyAcademiesSection({super.key, this.showHeaderActions = true});

  final bool showHeaderActions;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademyProvider>();

    if (provider.status == AcademyStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          provider.loadAcademies();
        }
      });
      return const AppLoading(label: 'Loading academies...', centered: false);
    }

    if (provider.status == AcademyStatus.loading &&
        provider.academies.isEmpty) {
      return const AppLoading(label: 'Loading academies...', centered: false);
    }

    if (provider.status == AcademyStatus.error && provider.academies.isEmpty) {
      return AppEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load academies',
        subtitle: provider.errorMessage,
        actionLabel: 'Retry',
        onAction: provider.loadAcademies,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        final actions = Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              label: 'View All',
              variant: AppButtonVariant.outlined,
              icon: Icons.grid_view_outlined,
              expanded: false,
              onPressed: () => context.push('/academies'),
            ),
            AppButton(
              label: 'Add Academy',
              icon: Icons.add_business_outlined,
              expanded: false,
              onPressed: () => context.push('/academies/register'),
            ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              title: 'Manage Academy',
              subtitle: 'Academies registered under your account',
              trailing: wide && showHeaderActions ? actions : null,
            ),
            if (!wide && showHeaderActions) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'View All',
                      variant: AppButtonVariant.outlined,
                      icon: Icons.grid_view_outlined,
                      onPressed: () => context.push('/academies'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Add Academy',
                      icon: Icons.add_business_outlined,
                      onPressed: () => context.push('/academies/register'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (provider.academies.isEmpty)
              AppEmptyState(
                icon: Icons.school_outlined,
                title: 'No academies yet',
                subtitle: 'Register your first academy to get started.',
                actionLabel: 'Register Academy',
                onAction: () => context.push('/academies/register'),
              )
            else
              _AcademyGrid(academies: provider.academies),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: AuthPalette.textPrimary(context),
      ),
    );
    final subtitleCol = subtitle == null
        ? null
        : Text(
            subtitle!,
            style: TextStyle(
              fontSize: 12.5,
              color: AuthPalette.subtitle(context),
            ),
          );

    if (trailing != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [label, ?subtitleCol],
          ),
          const Spacer(),
          trailing!,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            label,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Divider(
                height: 1,
                thickness: 1,
                color: AuthPalette.divider(context),
              ),
            ),
          ],
        ),
        if (subtitleCol != null) ...[
          const SizedBox(height: AppSpacing.xs),
          subtitleCol,
        ],
      ],
    );
  }
}

class _AcademyGrid extends StatelessWidget {
  const _AcademyGrid({required this.academies});

  final List<Academy> academies;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * AppSpacing.md) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final academy in academies)
              SizedBox(
                width: itemWidth,
                child: _AcademyCard(academy: academy),
              ),
          ],
        );
      },
    );
  }
}

class _AcademyCard extends StatelessWidget {
  const _AcademyCard({required this.academy});

  final Academy academy;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Delete Academy',
      message: 'Delete "${academy.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    final provider = context.read<AcademyProvider>();
    final success = await provider.deleteAcademy(academy.id);
    if (context.mounted) {
      AppSnackbar.show(
        context,
        success
            ? 'Academy deleted successfully.'
            : provider.errorMessage ?? 'Unable to delete the academy.',
        type: success ? AppFeedbackType.success : AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AuthPalette.surface(context),
        borderRadius: AppRadii.brMedium,
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AuthPalette.red.withValues(alpha: 0.08),
                  borderRadius: AppRadii.brMedium,
                  border: Border.all(
                    color: AuthPalette.red.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  size: 22,
                  color: AuthPalette.red,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      academy.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: AuthPalette.textPrimary(context),
                      ),
                    ),
                    if (academy.location.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AuthPalette.muted(context),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              academy.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AuthPalette.subtitle(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _CardActions(
                onEdit: () => context.push('/academies/${academy.id}/edit'),
                onDelete: () => _confirmDelete(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _FlatChip(
                label: academy.isPublic ? 'Public' : 'Private',
                dot: academy.isPublic ? AuthPalette.red : AuthPalette.muted(context),
              ),
              if (academy.branches.isNotEmpty)
                _FlatChip(
                  label:
                      '${academy.branches.length} Branch${academy.branches.length > 1 ? 'es' : ''}',
                  icon: Icons.business_outlined,
                ),
              if (academy.sports.isNotEmpty)
                _FlatChip(
                  label:
                      '${academy.sports.length} Sport${academy.sports.length > 1 ? 's' : ''}',
                  icon: Icons.sports_outlined,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            thickness: 1,
            color: AuthPalette.divider(context),
          ),
          const SizedBox(height: AppSpacing.md),
          _StatsPanel(
            metrics: [
              _MetricData(Icons.groups_outlined, '${academy.coachCount}', 'Coaches'),
              _MetricData(
                Icons.directions_run_outlined,
                '${academy.athleteCount}',
                'Athletes',
              ),
              _MetricData(
                Icons.emoji_events_outlined,
                '$_placeholderAchievements',
                'Achievements',
              ),
              _MetricData(
                Icons.calendar_month_outlined,
                '$_placeholderEstYear',
                'Est. Year',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.sports,
                  title: 'Manage Coach',
                  subtitle: 'Coaching staff',
                  onTap: () async {
                    await context.push(
                      '/academies/${academy.id}/coaches',
                      extra: academy,
                    );
                    if (context.mounted) {
                      context.read<AcademyProvider>().loadAcademies();
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionTile(
                  icon: Icons.directions_run_outlined,
                  title: 'Manage Athlete',
                  subtitle: 'Athletes & teams',
                  onTap: () async {
                    await context.push(
                      '/academies/${academy.id}/athletes',
                      extra: academy,
                    );
                    if (context.mounted) {
                      context.read<AcademyProvider>().loadAcademies();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.icon, this.count, this.label);

  final IconData icon;
  final String count;
  final String label;
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AuthPalette.bg(context),
        borderRadius: AppRadii.brMedium,
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final metric in metrics)
            Expanded(child: _Metric(metric: metric)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(metric.icon, size: 22, color: AuthPalette.muted(context)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          metric.count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: AuthPalette.textPrimary(context),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            metric.label,
            maxLines: 1,
            style: TextStyle(fontSize: 11, color: AuthPalette.subtitle(context)),
          ),
        ),
      ],
    );
  }
}

class _FlatChip extends StatelessWidget {
  const _FlatChip({required this.label, this.icon, this.dot});

  final String label;
  final IconData? icon;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: AppRadii.brPill,
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 13, color: AuthPalette.red),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AuthPalette.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clickable action tile with visible hover feedback so it reads as tappable.
class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: _hovered
              ? AuthPalette.red.withValues(alpha: 0.05)
              : AuthPalette.bg(context),
          borderRadius: AppRadii.brMedium,
          border: Border.all(
            color: _hovered
                ? AuthPalette.red.withValues(alpha: 0.5)
                : AuthPalette.border(context),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadii.brMedium,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AuthPalette.red.withValues(alpha: 0.08),
                      borderRadius: AppRadii.brSmall,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 19,
                      color: AuthPalette.red,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AuthPalette.textPrimary(context),
                            ),
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AuthPalette.subtitle(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: _hovered
                        ? AuthPalette.red
                        : AuthPalette.muted(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.brMedium,
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Edit Academy',
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: AuthPalette.muted(context),
            ),
          ),
          IconButton(
            tooltip: 'Delete Academy',
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: AuthPalette.red,
            ),
          ),
        ],
      ),
    );
  }
}