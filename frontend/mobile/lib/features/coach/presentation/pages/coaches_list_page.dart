import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/app_ambient_background.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../academy/domain/entities/academy.dart';
import '../../domain/entities/coach.dart';
import '../providers/coach_provider.dart';

class CoachesListPage extends StatefulWidget {
  const CoachesListPage({super.key, required this.academyId, this.academy});

  final String academyId;
  final Academy? academy;

  @override
  State<CoachesListPage> createState() => _CoachesListPageState();
}

class _CoachesListPageState extends State<CoachesListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CoachProvider>().loadCoaches(widget.academyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoachProvider>();
    final academy = widget.academy;

    return Scaffold(
      appBar: AppBar(title: const Text('Coaches')),
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
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSectionHeader(
                        title: academy?.name ?? 'Coaching Staff',
                        subtitle:
                            'Coaches associated with this academy can sign in with the credentials sent to their email.',
                        trailing: AppButton(
                          label: 'Add Coach',
                          icon: Icons.person_add_alt_1,
                          expanded: false,
                          onPressed: () => context.push(
                            '/academies/${widget.academyId}/coaches/add',
                            extra: academy,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildBody(provider),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CoachProvider provider) {
    if (provider.status == CoachLoadStatus.loading &&
        provider.coaches.isEmpty) {
      return const AppLoading(label: 'Loading coaches...', centered: false);
    }

    if (provider.status == CoachLoadStatus.error &&
        provider.coaches.isEmpty) {
      return AppEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load coaches',
        subtitle: provider.errorMessage,
        actionLabel: 'Retry',
        onAction: () => provider.loadCoaches(widget.academyId),
      );
    }

    if (provider.coaches.isEmpty) {
      return AppEmptyState(
        icon: Icons.sports_outlined,
        title: 'No coaches yet',
        subtitle: 'Add your first coach to send them sign-in credentials.',
        actionLabel: 'Add Coach',
        onAction: () => context.push(
          '/academies/${widget.academyId}/coaches/add',
          extra: widget.academy,
        ),
      );
    }

    return Column(
      children: [
        for (final coach in provider.coaches) ...[
          _CoachCard(
            academyId: widget.academyId,
            academy: widget.academy,
            coach: coach,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.academyId,
    required this.coach,
    this.academy,
  });

  final String academyId;
  final Academy? academy;
  final Coach coach;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Remove Coach',
      message:
          'Remove "${coach.fullName}" from this academy? This cannot be undone.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed != true) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    final provider = context.read<CoachProvider>();
    final success = await provider.deleteCoach(academyId, coach.coachId);
    if (context.mounted) {
      AppSnackbar.show(
        context,
        success
            ? 'Coach removed successfully.'
            : provider.errorMessage ?? 'Unable to remove the coach.',
        type: success ? AppFeedbackType.success : AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(coach.fullName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _StatusBadge(status: coach.status),
                        AppBadge(
                          label: coach.publicUserId,
                          icon: Icons.badge_outlined,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _CardActions(
                onEdit: () => context.push(
                  '/academies/$academyId/coaches/${coach.coachId}/edit',
                  extra: (academy: academy, coach: coach),
                ),
                onDelete: () => _confirmDelete(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(icon: Icons.mail_outline, value: coach.email),
          _DetailRow(icon: Icons.phone_outlined, value: coach.mobileNumber),
          if (coach.branchName != null)
            _DetailRow(icon: Icons.account_tree_outlined, value: coach.branchName!),
          if (coach.sports.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final sport in coach.sports)
                  AppBadge(
                    label: sport.specialization == null ||
                            sport.specialization!.trim().isEmpty
                        ? sport.name
                        : '${sport.name} · ${sport.specialization}',
                    icon: Icons.emoji_events_outlined,
                    compact: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CoachStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = status == CoachStatus.active;
    final backgroundColor =
        isActive ? scheme.tertiaryContainer : scheme.secondaryContainer;
    final foregroundColor =
        isActive ? scheme.onTertiaryContainer : scheme.onSecondaryContainer;

    return AppBadge(
      label: status.label,
      icon: isActive ? Icons.check_circle_outline : Icons.schedule,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      compact: true,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
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
            tooltip: 'Edit Coach',
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: 'Remove Coach',
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
          ),
        ],
      ),
    );
  }
}
