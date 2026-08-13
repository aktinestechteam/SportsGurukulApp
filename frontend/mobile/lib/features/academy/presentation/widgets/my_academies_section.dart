import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/academy.dart';
import '../providers/academy_provider.dart';

/// Sample statistics rendered on academy cards. Hardcoded placeholders until
/// the data model exposes real counts.
const int _placeholderAthletes = 120;
const int _placeholderCoaches = 12;
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
            AppSectionHeader(
              title: 'Register Academy',
              subtitle: 'Academies registered under your account',
              trailing: wide && showHeaderActions ? actions : null,
            ),
            if (!wide && showHeaderActions) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('/academies'),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('View All'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.push('/academies/register'),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Add Academy'),
                      ),
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

  List<Widget> _badges(ColorScheme scheme) => [
    StatusBadge(status: academy.isPublic ? 'Public' : 'Private'),
    if (academy.branches.isNotEmpty)
      AppBadge(
        label:
            '${academy.branches.length} Branch${academy.branches.length > 1 ? 'es' : ''}',
        icon: Icons.business_outlined,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
    if (academy.sports.isNotEmpty)
      AppBadge(
        label:
            '${academy.sports.length} Sport${academy.sports.length > 1 ? 's' : ''}',
        icon: Icons.sports_outlined,
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
      ),
  ];

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
    final scheme = Theme.of(context).colorScheme;
    final brand = BrandColors.of(context);
    final status = StatusColors.of(context);

    return AppCard(
      variant: AppCardVariant.interactive,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: brand.primaryGradient,
                  borderRadius: AppRadii.brMedium,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brand.indigoA.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_outlined,
                  size: 24,
                  color: Colors.white,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (academy.location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              academy.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final badge in _badges(scheme))
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: badge,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSpacing.md),
          _StatsPanel(
            metrics: [
              _MetricData(
                Icons.groups_outlined,
                '$_placeholderCoaches',
                'Coaches',
                status.success,
              ),
              _MetricData(
                Icons.directions_run_outlined,
                '$_placeholderAthletes',
                'Athletes',
                brand.teal,
              ),
              _MetricData(
                Icons.emoji_events_outlined,
                '$_placeholderAchievements',
                'Achievements',
                status.warning,
              ),
              _MetricData(
                Icons.calendar_month_outlined,
                '$_placeholderEstYear',
                'Est. Year',
                status.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final coachTile = _ActionTile(
                icon: Icons.sports,
                iconColor: scheme.secondary,
                iconBackground: scheme.secondaryContainer,
                title: 'Manage Coach',
                subtitle: 'Manage your coaching staff',
                onTap: () {
                  AppSnackbar.show(
                    context,
                    'Coach management is coming soon.',
                    type: AppFeedbackType.info,
                    actionLabel: 'Dismiss',
                    onAction: () =>
                        ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  );
                },
              );
              final athleteTile = _ActionTile(
                icon: Icons.directions_run_outlined,
                iconColor: scheme.tertiary,
                iconBackground: scheme.tertiaryContainer,
                title: 'Manage Athlete',
                subtitle: 'Manage your athletes & teams',
                onTap: () {
                  AppSnackbar.show(
                    context,
                    'Athlete management is coming soon.',
                    type: AppFeedbackType.info,
                    actionLabel: 'Dismiss',
                    onAction: () =>
                        ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  );
                },
              );

              if (constraints.maxWidth >= 280) {
                return Row(
                  children: [
                    Expanded(child: coachTile),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: athleteTile),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  coachTile,
                  const SizedBox(height: AppSpacing.sm),
                  athleteTile,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.icon, this.count, this.label, this.color);

  final IconData icon;
  final String count;
  final String label;
  final Color color;
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadii.brMedium,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final metric in metrics)
            Expanded(
              child: _Metric(metric: metric),
            ),
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(metric.icon, size: 24, color: metric.color),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          metric.count,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            metric.label,
            maxLines: 1,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
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
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: AppRadii.brMedium,
            border: Border.all(
              color: _hovered
                  ? scheme.primary.withValues(alpha: 0.4)
                  : scheme.outlineVariant,
            ),
            boxShadow: _hovered ? AppShadows.subtle : AppShadows.none,
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadii.brMedium,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.iconBackground.withValues(alpha: 0.9),
                      borderRadius: AppRadii.brSmall,
                    ),
                    child: Icon(widget.icon, size: 20, color: widget.iconColor),
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadii.brMedium,
        border: Border.all(color: scheme.outlineVariant),
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
              color: scheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: 'Delete Academy',
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
          ),
        ],
      ),
    );
  }
}
