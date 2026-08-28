import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/utils/time_format.dart';
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
import '../../domain/entities/batch.dart';
import '../providers/batch_provider.dart';

class BatchesListPage extends StatefulWidget {
  const BatchesListPage({super.key, required this.academyId, this.academy});

  final String academyId;
  final Academy? academy;

  @override
  State<BatchesListPage> createState() => _BatchesListPageState();
}

class _BatchesListPageState extends State<BatchesListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BatchProvider>().loadBatches(widget.academyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BatchProvider>();
    final academy = widget.academy;

    return Scaffold(
      appBar: AppBar(title: const Text('Batches')),
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
                        title: academy?.name ?? 'Batches',
                        subtitle:
                            'Training batches with schedules, coaches, and athletes.',
                        trailing: AppButton(
                          label: 'Create Batch',
                          icon: Icons.add,
                          expanded: false,
                          onPressed: () => context.push(
                            '/academies/${widget.academyId}/batches/add',
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

  Widget _buildBody(BatchProvider provider) {
    if (provider.status == BatchLoadStatus.loading &&
        provider.batches.isEmpty) {
      return const AppLoading(label: 'Loading batches...', centered: false);
    }

    if (provider.status == BatchLoadStatus.error &&
        provider.batches.isEmpty) {
      return AppEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load batches',
        subtitle: provider.errorMessage,
        actionLabel: 'Retry',
        onAction: () => provider.loadBatches(widget.academyId),
      );
    }

    if (provider.batches.isEmpty) {
      return AppEmptyState(
        icon: Icons.groups_outlined,
        title: 'No batches yet',
        subtitle: 'Create your first batch to organize training sessions.',
        actionLabel: 'Create Batch',
        onAction: () => context.push(
          '/academies/${widget.academyId}/batches/add',
          extra: widget.academy,
        ),
      );
    }

    return Column(
      children: [
        for (final batch in provider.batches) ...[
          _BatchCard(
            academyId: widget.academyId,
            academy: widget.academy,
            batch: batch,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.academyId,
    required this.batch,
    this.academy,
  });

  final String academyId;
  final Academy? academy;
  final Batch batch;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Delete Batch',
      message:
          'Delete "${batch.name}"? This will remove all schedule slots and assignments. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final provider = context.read<BatchProvider>();
    final success = await provider.deleteBatch(academyId, batch.batchId);
    if (context.mounted) {
      AppSnackbar.show(
        context,
        success
            ? 'Batch deleted successfully.'
            : provider.errorMessage ?? 'Unable to delete the batch.',
        type: success ? AppFeedbackType.success : AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final sortedSlots = batch.slots.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: icon + name + sport + actions ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: brand.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.groups, color: Colors.white, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (batch.sportName != null) ...[
                      const SizedBox(height: 4),
                      AppBadge(
                        label: batch.sportName!,
                        icon: Icons.emoji_events_outlined,
                        compact: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit Batch',
                      onPressed: () => context.push(
                        '/academies/$academyId/batches/${batch.batchId}/edit',
                        extra: (academy: academy, batch: batch),
                      ),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.edit_outlined, size: 18, color: scheme.onSurfaceVariant),
                    ),
                    IconButton(
                      tooltip: 'Delete Batch',
                      onPressed: () => _confirmDelete(context),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Description ──
          if (batch.description != null && batch.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              batch.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],

          // ── Divider ──
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: AppSpacing.md),

          // ── Batch Date Range ──
          if (batch.startDate != null || batch.endDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.date_range_outlined, size: 16, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      batch.startDate != null && batch.endDate != null
                          ? '${batch.startDate!.day}/${batch.startDate!.month}/${batch.startDate!.year} – ${batch.endDate!.day}/${batch.endDate!.month}/${batch.endDate!.year}'
                          : batch.startDate != null
                              ? 'From ${batch.startDate!.day}/${batch.startDate!.month}/${batch.startDate!.year}'
                              : 'Until ${batch.endDate!.day}/${batch.endDate!.month}/${batch.endDate!.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Schedule Slots ──
          _SectionTitle(icon: Icons.schedule_outlined, title: 'Schedule'),
          if (batch.slots.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'No schedule slots configured.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...sortedSlots.map((slot) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: AppBadge(
                      label:
                          '${TimeFormat.clock(slot.startTime)} – ${TimeFormat.clock(slot.endTime)}',
                      icon: Icons.access_time,
                      compact: true,
                    ),
                  ),
                  if (slot.location != null && slot.location!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: AppBadge(
                        label: slot.location!,
                        icon: Icons.location_on_outlined,
                        compact: true,
                      ),
                    ),
                  ],
                ],
              ),
            )),

          // ── Divider ──
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: AppSpacing.md),

          // ── Coaches ──
          _SectionTitle(icon: Icons.sports, title: 'Coaches (${batch.coaches.length})'),
          if (batch.coaches.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'No coaches assigned.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...batch.coaches.map((coach) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      _initials(coach.fullName),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      coach.fullName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (coach.specialization != null && coach.specialization!.isNotEmpty)
                    Flexible(
                      child: AppBadge(
                        label: coach.specialization!,
                        compact: true,
                      ),
                    ),
                ],
              ),
            )),

          // ── Divider ──
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: AppSpacing.md),

          // ── Athletes ──
          _SectionTitle(icon: Icons.person_outline, title: 'Athletes (${batch.athletes.length})'),
          if (batch.athletes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'No athletes assigned.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...batch.athletes.map((athlete) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: scheme.tertiaryContainer,
                    child: Text(
                      _initials(athlete.fullName),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      athlete.fullName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (athlete.primarySport != null && athlete.primarySport!.isNotEmpty)
                    Flexible(
                      child: AppBadge(
                        label: athlete.primarySport!,
                        icon: Icons.emoji_events_outlined,
                        compact: true,
                      ),
                    ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}
