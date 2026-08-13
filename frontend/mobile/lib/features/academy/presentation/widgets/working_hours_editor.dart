import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../domain/repositories/academy_repository.dart';

const dayLabels = <int, String>{
  1: 'Monday',
  2: 'Tuesday',
  3: 'Wednesday',
  4: 'Thursday',
  5: 'Friday',
  6: 'Saturday',
  0: 'Sunday',
};

/// Display order: Monday .. Sunday.
const workingDayOrder = <int>[1, 2, 3, 4, 5, 6, 0];

List<AcademyWorkingHourInput> defaultWorkingHours() {
  return [
    for (final day in workingDayOrder)
      if (day == 0)
        const AcademyWorkingHourInput(
          dayOfWeek: 0,
          openTime: '07:00',
          closeTime: '18:00',
        )
      else
        AcademyWorkingHourInput(
          dayOfWeek: day,
          openTime: '06:00',
          closeTime: '21:00',
        ),
  ];
}

/// Ensures every day of the week is present, preserving existing values.
List<AcademyWorkingHourInput> completeWorkingHours(
  List<AcademyWorkingHourInput> hours,
) {
  final byDay = {for (final h in hours) h.dayOfWeek: h};
  return [
    for (final day in workingDayOrder) byDay[day] ?? defaultWorkingHours().firstWhere((h) => h.dayOfWeek == day),
  ];
}

TimeOfDay? parseTimeOfDay(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final parts = value.split(':');
  if (parts.length < 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }
  return TimeOfDay(hour: hour, minute: minute);
}

String formatTimeOfDay(TimeOfDay? time) {
  if (time == null) {
    return '--:--';
  }
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class WorkingHoursEditor extends StatelessWidget {
  const WorkingHoursEditor({
    super.key,
    required this.hours,
    required this.onChanged,
  });

  final List<AcademyWorkingHourInput> hours;
  final ValueChanged<List<AcademyWorkingHourInput>> onChanged;

  void _update(AcademyWorkingHourInput updated) {
    onChanged([
      for (final h in hours) h.dayOfWeek == updated.dayOfWeek ? updated : h,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(
            title: 'Working Hours',
            subtitle: 'Operating hours used for scheduling and bookings',
          ),
          for (final day in workingDayOrder) ...[
            _DayRow(
              label: dayLabels[day] ?? 'Day',
              hour: hours.firstWhere(
                (h) => h.dayOfWeek == day,
                orElse: () => defaultWorkingHours().firstWhere(
                  (h) => h.dayOfWeek == day,
                ),
              ),
              onChanged: _update,
            ),
            if (day != workingDayOrder.last)
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.label,
    required this.hour,
    required this.onChanged,
  });

  final String label;
  final AcademyWorkingHourInput hour;
  final ValueChanged<AcademyWorkingHourInput> onChanged;

  Future<void> _pickTime(BuildContext context, {required bool open}) async {
    final current = open ? hour.openTime : hour.closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: parseTimeOfDay(current) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) {
      return;
    }
    final value = formatTimeOfDay(picked);
    onChanged(
      AcademyWorkingHourInput(
        dayOfWeek: hour.dayOfWeek,
        openTime: open ? value : hour.openTime,
        closeTime: open ? hour.closeTime : value,
        isClosed: hour.isClosed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = hour.isClosed;

    Widget timeSlot(String label, String value, VoidCallback onTap) {
      final background = disabled
          ? scheme.surfaceContainerHighest
          : scheme.secondaryContainer.withValues(alpha: 0.6);
      return Expanded(
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: AppRadii.br(AppRadii.medium),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadii.br(AppRadii.medium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: disabled
                        ? scheme.onSurfaceVariant
                        : scheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  disabled ? '--:--' : value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: disabled ? scheme.onSurfaceVariant : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          timeSlot('Open', formatTimeOfDay(parseTimeOfDay(hour.openTime)), () => _pickTime(context, open: true)),
          const SizedBox(width: AppSpacing.sm),
          timeSlot('Close', formatTimeOfDay(parseTimeOfDay(hour.closeTime)), () => _pickTime(context, open: false)),
          const SizedBox(width: AppSpacing.sm),
          _ClosedToggle(
            value: hour.isClosed,
            onChanged: (closed) {
              onChanged(
                AcademyWorkingHourInput(
                  dayOfWeek: hour.dayOfWeek,
                  openTime: hour.openTime,
                  closeTime: hour.closeTime,
                  isClosed: closed,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ClosedToggle extends StatelessWidget {
  const _ClosedToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: value ? 'Closed' : 'Open',
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: AppRadii.br(AppRadii.medium),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: value
                ? scheme.errorContainer.withValues(alpha: 0.6)
                : scheme.surfaceContainerHighest,
            borderRadius: AppRadii.br(AppRadii.medium),
          ),
          child: Icon(
            value ? Icons.close : Icons.check,
            size: 18,
            color: value ? scheme.error : scheme.primary,
          ),
        ),
      ),
    );
  }
}
