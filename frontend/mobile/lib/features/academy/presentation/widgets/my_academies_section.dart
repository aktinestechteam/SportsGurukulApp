import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_radii.dart';
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

    if (provider.status == AcademyStatus.error &&
        provider.academies.isEmpty) {
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
        final showActions = showHeaderActions && constraints.maxWidth >= 560;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: 'Register Academy',
              subtitle: 'Academies registered under your account',
              trailing: showActions
                  ? Wrap(
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
                    )
                  : null,
            ),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Delete Academy',
      message:
          'Delete "${academy.name}"? This action cannot be undone.',
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
        type: success
            ? AppFeedbackType.success
            : AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = BrandColors.of(context);

    return AppCard(
      variant: AppCardVariant.interactive,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: brand.subtleGradient,
                  borderRadius: AppRadii.brMedium,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Icon(
                  Icons.school_outlined,
                  size: 22,
                  color: scheme.primary,
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (academy.location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        academy.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              StatusBadge(
                status: academy.isPublic ? 'Public' : 'Private',
              ),
              if (academy.branches.isNotEmpty)
                AppBadge(
                  label: '${academy.branches.length} Branch${academy.branches.length > 1 ? 'es' : ''}',
                  icon: Icons.business_outlined,
                ),
              if (academy.sports.isNotEmpty)
                AppBadge(
                  label: '${academy.sports.length} Sport${academy.sports.length > 1 ? 's' : ''}',
                  icon: Icons.sports_outlined,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/academies/${academy.id}/edit'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
