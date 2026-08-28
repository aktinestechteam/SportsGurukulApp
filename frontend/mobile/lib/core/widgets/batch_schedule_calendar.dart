import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/auth_palette.dart';
import 'app_empty_state.dart';

enum UserRole { coach, athlete }

/// A single recurring session slot belonging to a batch.
///
/// Slots are time-based only; the batch's start/end date range determines
/// which days the session appears on in the calendar.
class CalendarScheduleSlot {
  const CalendarScheduleSlot({
    required this.batchId,
    required this.batchName,
    this.sportName,
    required this.startTime,
    required this.endTime,
    this.location,
    this.coachName,
    this.athletesCount = 0,
    this.startDate,
    this.endDate,
  });

  final String batchId;
  final String batchName;
  final String? sportName;

  final String startTime;
  final String endTime;
  final String? location;
  final String? coachName;
  final int athletesCount;
  final DateTime? startDate;
  final DateTime? endDate;
}

// ---------------------------------------------------------------------------
// Top-level helpers
// ---------------------------------------------------------------------------

/// Strip time components so date comparisons work correctly regardless of
/// whether the input came from UTC or local DateTime.
DateTime _dateOnly(DateTime d) {
  final local = d.isUtc ? d.toLocal() : d;
  return DateTime(local.year, local.month, local.day);
}

String _monthYearLabel(DateTime d) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${months[d.month - 1]} ${d.year}';
}

String _fullDateHeading(DateTime d) {
  const days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
}

(int minutes, int hours, int mins) _parseTime(String time) {
  final cleaned = time.trim();
  final isAmPm = cleaned.toUpperCase().contains('AM') ||
      cleaned.toUpperCase().contains('PM');

  if (isAmPm) {
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
        .firstMatch(cleaned);
    if (match != null) {
      var h = int.parse(match.group(1)!);
      final m = int.parse(match.group(2)!);
      final period = match.group(3)!.toUpperCase();
      if (period == 'AM' && h == 12) h = 0;
      if (period == 'PM' && h != 12) h += 12;
      return (h * 60 + m, h, m);
    }
  }

  final parts = cleaned.split(':');
  if (parts.length >= 2) {
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return (h * 60 + m, h, m);
  }
  return (0, 0, 0);
}

String _formatTimeLabel(int hours, int mins) {
  final period = hours >= 12 ? 'PM' : 'AM';
  final h12 = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours);
  return '${h12.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} $period';
}

String _batchRangeLabel(CalendarScheduleSlot slot) {
  String fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  if (slot.startDate != null && slot.endDate != null) {
    return '${fmt(slot.startDate!)} – ${fmt(slot.endDate!)}';
  } else if (slot.startDate != null) {
    return 'From ${fmt(slot.startDate!)}';
  } else if (slot.endDate != null) {
    return 'Until ${fmt(slot.endDate!)}';
  }
  return '';
}

/// Returns true when [slot] should appear on [date].
///
/// A slot appears on a date when BOTH conditions hold:
///   1. [date] is on or after the batch's startDate (if set).
///   2. [date] is on or before the batch's endDate (if set).
///
/// With day-of-week selection removed, a batch's session runs on **every**
/// day within its date range — the timeline shows it on each of those days
/// (e.g. Monday through Sunday across the range).
bool _isSlotActiveOnDate(CalendarScheduleSlot slot, DateTime date) {
  final d = _dateOnly(date);
  if (slot.startDate != null && d.isBefore(_dateOnly(slot.startDate!))) {
    return false;
  }
  if (slot.endDate != null && d.isAfter(_dateOnly(slot.endDate!))) {
    return false;
  }
  return true;
}

/// Returns true when [date] falls within the date range of *any* slot's
/// parent batch — used to highlight calendar days even when no session is
/// scheduled on that specific weekday.
bool _isDateInRange(List<CalendarScheduleSlot> slots, DateTime date) {
  final d = _dateOnly(date);
  for (final slot in slots) {
    final start = slot.startDate != null ? _dateOnly(slot.startDate!) : null;
    final end = slot.endDate != null ? _dateOnly(slot.endDate!) : null;
    if (start != null && d.isBefore(start)) continue;
    if (end != null && d.isAfter(end)) continue;
    return true;
  }
  return false;
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------
class BatchScheduleCalendar extends StatefulWidget {
  const BatchScheduleCalendar({
    super.key,
    required this.slots,
    required this.role,
    this.onSessionTap,
  });

  final List<CalendarScheduleSlot> slots;
  final UserRole role;
  final ValueChanged<CalendarScheduleSlot>? onSessionTap;

  @override
  State<BatchScheduleCalendar> createState() => _BatchScheduleCalendarState();
}

class _BatchScheduleCalendarState extends State<BatchScheduleCalendar> {
  late DateTime _today;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(DateTime.now());
    _selectedDate = _today;
  }

  bool _hasSessionsOnDate(DateTime date) =>
      widget.slots.any((s) => _isSlotActiveOnDate(s, date));

  bool _isDateInAnyBatchRange(DateTime date) =>
      _isDateInRange(widget.slots, date);

  void _selectDate(DateTime date) {
    final d = _dateOnly(date);
    if (d == _selectedDate) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedDate = d);
  }

  void _onTimelineHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 50) return;
    if (velocity > 0) {
      _selectDate(_selectedDate.subtract(const Duration(days: 1)));
    } else {
      _selectDate(_selectedDate.add(const Duration(days: 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MonthCalendar(
          selectedDate: _selectedDate,
          today: _today,
          hasSessionsOnDate: _hasSessionsOnDate,
          isDateInRange: _isDateInAnyBatchRange,
          onDaySelected: _selectDate,
        ),
        Divider(height: 1, thickness: 1, color: AuthPalette.border(context)),
        GestureDetector(
          onHorizontalDragEnd: _onTimelineHorizontalDragEnd,
          child: _DayTimeline(
            date: _selectedDate,
            allSlots: widget.slots,
            isToday: _selectedDate == _today,
            isInBatchRange: _isDateInAnyBatchRange(_selectedDate),
            onSessionTap: widget.onSessionTap,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Month calendar — a standard month grid that drives the day timeline
// ---------------------------------------------------------------------------

class _MonthCalendar extends StatefulWidget {
  const _MonthCalendar({
    required this.selectedDate,
    required this.today,
    required this.hasSessionsOnDate,
    required this.isDateInRange,
    required this.onDaySelected,
  });

  final DateTime selectedDate;
  final DateTime today;
  final bool Function(DateTime) hasSessionsOnDate;
  final bool Function(DateTime) isDateInRange;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<_MonthCalendar> {
  late DateTime _focusedMonth;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    final s = _dateOnly(widget.selectedDate);
    _focusedMonth = DateTime(s.year, s.month);
  }

  @override
  void didUpdateWidget(covariant _MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final s = _dateOnly(widget.selectedDate);
    if (s.year != _focusedMonth.year || s.month != _focusedMonth.month) {
      _focusedMonth = DateTime(s.year, s.month);
    }
  }

  void _changeMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
  }

  List<DateTime?> _cellsForMonth() {
    final y = _focusedMonth.year;
    final m = _focusedMonth.month;
    final first = DateTime(y, m, 1);
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final leadingBlanks = first.weekday - 1;
    final cells = <DateTime?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var d = 1; d <= daysInMonth; d++) DateTime(y, m, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _dateOnly(widget.selectedDate);
    final today = _dateOnly(widget.today);
    final cells = _cellsForMonth();

    var monthHasRange = false;
    for (final cell in cells) {
      if (cell != null && widget.isDateInRange(cell)) {
        monthHasRange = true;
        break;
      }
    }

    return Container(
      color: AuthPalette.surface(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              3,
              AppSpacing.xs,
              2,
            ),
            child: Row(
              children: [
                _CalendarNavButton(
                  icon: Icons.chevron_left,
                  onTap: () => _changeMonth(-1),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _monthYearLabel(_focusedMonth),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AuthPalette.textPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _CalendarNavButton(
                  icon: Icons.chevron_right,
                  onTap: () => _changeMonth(1),
                ),
                const SizedBox(width: AppSpacing.xs),
                if (selected != today)
                  GestureDetector(
                    onTap: () => widget.onDaySelected(today),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AuthPalette.red.withValues(alpha: 0.08),
                        borderRadius: AppRadii.brPill,
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AuthPalette.red,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                _CalendarNavButton(
                  icon: _expanded ? Icons.expand_less : Icons.expand_more,
                  onTap: _toggleExpanded,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: AppMotion.fast,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _weekHeader(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xs,
                          0,
                          AppSpacing.xs,
                          AppSpacing.xs,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var row = 0; row < cells.length ~/ 7; row++) ...[
                              if (row > 0) const SizedBox(height: 1),
                              Row(
                                children: [
                                  for (var col = 0; col < 7; col++) ...[
                                    if (col > 0) const SizedBox(width: 2),
                                    Expanded(
                                      child: _buildCell(
                                        cells[row * 7 + col],
                                        selected: selected,
                                        today: today,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                            if (monthHasRange) ...[
                              const SizedBox(height: 4),
                              const _RangeLegend(),
                              const SizedBox(height: 2),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _weekHeader() {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            child: Center(
              child: Text(
                dayNames[i].toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AuthPalette.muted(context),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCell(
    DateTime? date, {
    required DateTime selected,
    required DateTime today,
  }) {
    final d = date;
    if (d == null) return const SizedBox(height: 38);

    final isSelected = _dateOnly(d) == selected;
    final isToday = _dateOnly(d) == today;

    return SizedBox(
      height: 38,
      child: GestureDetector(
        onTap: () => widget.onDaySelected(d),
        behavior: HitTestBehavior.opaque,
        child: _MonthDayCell(
          date: d,
          isSelected: isSelected,
          isToday: isToday,
          isInRange: widget.isDateInRange(d),
          hasSessions: widget.hasSessionsOnDate(d),
        ),
      ),
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AuthPalette.red.withValues(alpha: 0.08),
          borderRadius: AppRadii.brSmall,
        ),
        child: Icon(icon, size: 18, color: AuthPalette.red),
      ),
    );
  }
}

class _RangeLegend extends StatelessWidget {
  const _RangeLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AuthPalette.red.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Highlighted days are within your batch period(s)',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontSize: 10,
              color: AuthPalette.muted(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isInRange,
    required this.hasSessions,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isInRange;
  final bool hasSessions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 2),
        AnimatedContainer(
          duration: AppMotion.fast,
          width: 30,
          height: 30,
          decoration: isSelected
              ? BoxDecoration(
                  color: AuthPalette.red,
                  shape: BoxShape.circle,
                )
              : isToday
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AuthPalette.red.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    )
                  : isInRange
                      ? BoxDecoration(
                          color: AuthPalette.red.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        )
                      : null,
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : isToday
                      ? AuthPalette.red
                      : isInRange
                          ? AuthPalette.red.withValues(alpha: 0.85)
                          : AuthPalette.textPrimary(context),
            ),
          ),
        ),
        const SizedBox(height: 2),
        if (hasSessions)
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.85)
                  : AuthPalette.red.withValues(alpha: 0.55),
            ),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Day timeline
// ---------------------------------------------------------------------------

class _DayTimeline extends StatelessWidget {
  const _DayTimeline({
    required this.date,
    required this.allSlots,
    required this.isToday,
    required this.isInBatchRange,
    this.onSessionTap,
  });

  final DateTime date;

  /// Full slot list — used to surface the batch(es) whose range covers [date]
  /// even when no session falls on this weekday.
  final List<CalendarScheduleSlot> allSlots;

  final bool isToday;
  final bool isInBatchRange;
  final ValueChanged<CalendarScheduleSlot>? onSessionTap;

  /// Batches whose date range covers [date] — one representative slot per
  /// batch, deduplicated by batchId and sorted by batch name. Every day inside
  /// a batch period (with or without a session) renders one [_ScheduleCard].
  List<CalendarScheduleSlot> _activeBatchSlots() {
    final d = _dateOnly(date);
    final seen = <String>{};
    final slots = <CalendarScheduleSlot>[];
    for (final slot in allSlots) {
      if (seen.contains(slot.batchId)) continue;
      final start =
          slot.startDate != null ? _dateOnly(slot.startDate!) : null;
      final end = slot.endDate != null ? _dateOnly(slot.endDate!) : null;
      if (start != null && d.isBefore(start)) continue;
      if (end != null && d.isAfter(end)) continue;
      seen.add(slot.batchId);
      slots.add(slot);
    }
    slots.sort((a, b) => a.batchName.compareTo(b.batchName));
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final activeBatchSlots =
        isInBatchRange ? _activeBatchSlots() : <CalendarScheduleSlot>[];

    final heading = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              _fullDateHeading(date),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AuthPalette.textPrimary(context),
              ),
            ),
          ),
          if (isInBatchRange)
            _ActiveBatchPill(label: 'Active batch day'),
        ],
      ),
    );

    if (activeBatchSlots.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading,
          AppEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No sessions on this day',
            compact: true,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < activeBatchSlots.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _ScheduleCard(
                  batch: activeBatchSlots[i],
                  allSlots: allSlots,
                  isToday: isToday,
                  onTap: onSessionTap != null
                      ? () => onSessionTap!(activeBatchSlots[i])
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Schedule card — the same card rendered for every day inside a batch range
// ---------------------------------------------------------------------------

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.batch,
    required this.allSlots,
    required this.isToday,
    this.onTap,
  });

  final CalendarScheduleSlot batch;

  /// Every slot of the calendar — used to render [batch]'s weekly schedule.
  final List<CalendarScheduleSlot> allSlots;

  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sortedSlots = List<CalendarScheduleSlot>.from(
      allSlots.where((s) => s.batchId == batch.batchId),
    )..sort((a, b) =>
        _parseTime(a.startTime).$1.compareTo(_parseTime(b.startTime).$1));

    final borderColor = isToday
        ? AuthPalette.red.withValues(alpha: 0.55)
        : AuthPalette.red.withValues(alpha: 0.25);
    final borderWidth = isToday ? 1.5 : 1.0;
    final cardColor = isToday
        ? AuthPalette.surface(context)
        : AuthPalette.red.withValues(alpha: 0.03);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: AppRadii.brMedium,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AuthPalette.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    batch.batchName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AuthPalette.textPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AuthPalette.muted(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (batch.sportName != null && batch.sportName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _InfoRow(
                  icon: Icons.sports_outlined,
                  text: batch.sportName!,
                ),
              ),
            if (batch.coachName != null && batch.coachName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _InfoRow(
                  icon: Icons.person_outline,
                  text: batch.coachName!,
                ),
              ),
            if (batch.athletesCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _InfoRow(
                  icon: Icons.people_outline,
                  text: '${batch.athletesCount} athletes',
                ),
              ),
            if (batch.startDate != null || batch.endDate != null)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _InfoRow(
                  icon: Icons.date_range_outlined,
                  text: _batchRangeLabel(batch),
                ),
              ),
            if (sortedSlots.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Divider(height: 1, color: AuthPalette.border(context)),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'WEEKLY SCHEDULE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AuthPalette.muted(context),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              for (final slot in sortedSlots)
                _ScheduleSlotRow(slot: slot),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleSlotRow extends StatelessWidget {
  const _ScheduleSlotRow({required this.slot});

  final CalendarScheduleSlot slot;

  @override
  Widget build(BuildContext context) {
    final startParsed = _parseTime(slot.startTime);
    final endParsed = _parseTime(slot.endTime);
    final startLabel = _formatTimeLabel(startParsed.$2, startParsed.$3);
    final endLabel = _formatTimeLabel(endParsed.$2, endParsed.$3);
    final location = (slot.location != null && slot.location!.isNotEmpty)
        ? ' · ${slot.location}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 13, color: AuthPalette.muted(context)),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Text(
              '$startLabel – $endLabel$location',
              style: TextStyle(
                fontSize: 12,
                color: AuthPalette.subtitle(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _ActiveBatchPill extends StatelessWidget {
  const _ActiveBatchPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AuthPalette.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AuthPalette.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AuthPalette.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AuthPalette.muted(context)),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AuthPalette.subtitle(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}