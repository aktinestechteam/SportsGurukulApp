import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependencies.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/app_ambient_background.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../academy/domain/entities/academy.dart';
import '../../../coach/domain/entities/coach.dart';
import '../../../athlete/domain/entities/athlete.dart';
import '../../domain/entities/batch.dart';
import '../../domain/repositories/batch_repository.dart';
import '../providers/batch_provider.dart';

class AddBatchPage extends StatefulWidget {
  const AddBatchPage({
    super.key,
    required this.academyId,
    this.academy,
    this.batch,
  });

  final String academyId;
  final Academy? academy;
  final Batch? batch;

  @override
  State<AddBatchPage> createState() => _AddBatchPageState();
}

class _AddBatchPageState extends State<AddBatchPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _selectedSportId;
  String? _selectedSportName;
  final List<BatchSlotInput> _slots = [];
  final List<String> _selectedCoachIds = [];
  final List<String> _selectedAthleteIds = [];
  DateTime? _startDate;
  DateTime? _endDate;
  List<Coach> _availableCoaches = [];
  List<Athlete> _availableAthletes = [];
  bool _loadingCoaches = false;
  bool _loadingAthletes = false;
  int _currentStep = 0;

  bool get _isEditing => widget.batch != null;

  @override
  void initState() {
    super.initState();
    final batch = widget.batch;
    _nameController = TextEditingController(text: batch?.name ?? '');
    _descriptionController = TextEditingController(text: batch?.description ?? '');
    _selectedSportId = batch?.sportId;
    _selectedSportName = batch?.sportName;
    if (batch != null) {
      _slots.addAll(batch.slots.map((s) => BatchSlotInput(
        dayOfWeek: s.dayOfWeek,
        startTime: s.startTime,
        endTime: s.endTime,
        location: s.location,
      )));
      _selectedCoachIds.addAll(batch.coaches.map((c) => c.coachId));
      _selectedAthleteIds.addAll(batch.athletes.map((a) => a.athleteId));
      _startDate = batch.startDate;
      _endDate = batch.endDate;
    }
    if (_selectedSportId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadCoachesAndAthletes(_selectedSportId!);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSportSelected(String sportId, String sportName) {
    if (_selectedSportId == sportId) return;
    setState(() {
      _selectedSportId = sportId;
      _selectedSportName = sportName;
      _selectedCoachIds.clear();
      _selectedAthleteIds.clear();
      _availableCoaches.clear();
      _availableAthletes.clear();
    });
    _loadCoachesAndAthletes(sportId);
  }

  Future<void> _loadCoachesAndAthletes(String sportId) async {
    setState(() {
      _loadingCoaches = true;
      _loadingAthletes = true;
    });

    try {
      final api = Dependencies.apiClient;
      final coachData = await api.get(
        '/academies/${widget.academyId}/coaches?sportId=$sportId',
      );
      final athleteData = await api.get(
        '/academies/${widget.academyId}/athletes?sportId=$sportId',
      );

      if (mounted) {
        setState(() {
          _availableCoaches = (coachData is List ? coachData : [])
              .map((e) => Coach.fromJson((e as Map).cast<String, dynamic>()))
              .toList();
          _availableAthletes = (athleteData is List ? athleteData : [])
              .map((e) => Athlete.fromJson((e as Map).cast<String, dynamic>()))
              .toList();
          _loadingCoaches = false;
          _loadingAthletes = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingCoaches = false;
          _loadingAthletes = false;
        });
      }
    }
  }

  void _toggleCoach(String coachId) {
    setState(() {
      if (_selectedCoachIds.contains(coachId)) {
        _selectedCoachIds.remove(coachId);
      } else {
        _selectedCoachIds.add(coachId);
      }
    });
  }

  void _toggleAthlete(String athleteId) {
    setState(() {
      if (_selectedAthleteIds.contains(athleteId)) {
        _selectedAthleteIds.remove(athleteId);
      } else {
        _selectedAthleteIds.add(athleteId);
      }
    });
  }

  void _addSlot() async {
    final result = await _showAddSlotDialog();
    if (result != null) {
      setState(() => _slots.add(result));
    }
  }

  Future<BatchSlotInput?> _showAddSlotDialog() async {
    DayOfWeek selectedDay = DayOfWeek.monday;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    final locationController = TextEditingController();

    String formatTime(TimeOfDay t) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    String formatTimeDisplay(TimeOfDay t) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    Future<void> pickTime(bool isStart, StateSetter setDialogState) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: isStart ? startTime : endTime,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: Theme(
              data: Theme.of(context).copyWith(
                timePickerTheme: TimePickerThemeData(
                  hourMinuteColor: Theme.of(context).colorScheme.primary,
                  hourMinuteTextColor: Theme.of(context).colorScheme.onPrimary,
                  dialHandColor: Theme.of(context).colorScheme.primary,
                  dialBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  entryModeIconColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              child: child!,
            ),
          );
        },
      );
      if (picked != null) {
        setDialogState(() {
          if (isStart) {
            startTime = picked;
          } else {
            endTime = picked;
          }
        });
      }
    }

    return showDialog<BatchSlotInput>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Schedule Slot'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<DayOfWeek>(
                initialValue: selectedDay,
                decoration: const InputDecoration(labelText: 'Day'),
                items: DayOfWeek.values
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedDay = v);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => pickTime(true, setDialogState),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(formatTimeDisplay(startTime)),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => pickTime(false, setDialogState),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(formatTimeDisplay(endTime)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                BatchSlotInput(
                  dayOfWeek: selectedDay,
                  startTime: formatTime(startTime),
                  endTime: formatTime(endTime),
                  location: locationController.text.trim().isEmpty
                      ? null
                      : locationController.text.trim(),
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0:
        return _formKey.currentState?.validate() == true && _selectedSportId != null;
      case 1:
        return true;
      case 2:
        return true;
      case 3:
        return _slots.isNotEmpty;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < 3 && _canProceedFromStep(_currentStep)) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _save() async {
    final input = BatchRequestInput(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      sportId: _selectedSportId,
      startDate: _startDate,
      endDate: _endDate,
      slots: _slots,
      coachIds: _selectedCoachIds,
      athleteIds: _selectedAthleteIds,
    );

    final provider = context.read<BatchProvider>();
    bool success;
    if (_isEditing) {
      success = await provider.updateBatch(
        widget.academyId,
        widget.batch!.batchId,
        input,
      );
    } else {
      success = await provider.createBatch(widget.academyId, input);
    }

    if (mounted) {
      AppSnackbar.show(
        context,
        success
            ? (_isEditing ? 'Batch updated.' : 'Batch created.')
            : provider.errorMessage ?? 'Something went wrong.',
        type: success ? AppFeedbackType.success : AppFeedbackType.error,
      );
      if (success) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Batch' : 'Create Batch'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AppAmbientBackground()),
          Positioned.fill(
            child: Column(
              children: [
                _StepIndicator(currentStep: _currentStep),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppBreakpoints.horizontalPadding(context).add(
                      const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    ),
                    child: AppBreakpoints.constrain(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: _buildCurrentStep(),
                      ),
                    ),
                  ),
                ),
                _buildBottomBar(scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepDetails();
      case 1:
        return _buildStepCoaches();
      case 2:
        return _buildStepAthletes();
      case 3:
        return _buildStepSchedule();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: AppButton(
                  label: 'Back',
                  icon: Icons.arrow_back,
                  expanded: true,
                  onPressed: _prevStep,
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: _currentStep == 3
                    ? (_isEditing ? 'Update Batch' : 'Create Batch')
                    : 'Next',
                icon: _currentStep == 3
                    ? (_isEditing ? Icons.save : Icons.check)
                    : Icons.arrow_forward,
                expanded: true,
                onPressed: _currentStep == 3
                    ? (_canProceedFromStep(3) ? _save : null)
                    : (_canProceedFromStep(_currentStep) ? _nextStep : null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDetails() {
    final academy = widget.academy;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batch Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Batch Name *',
                    hintText: 'e.g., Morning Cricket Batch',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required.' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Sport *',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Coaches and athletes will be filtered by this sport.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (academy == null || academy.sports.isEmpty)
                  Text(
                    'No sports configured for this academy.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.error,
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSportId,
                    decoration: const InputDecoration(
                      labelText: 'Sport *',
                      hintText: 'Select a sport',
                    ),
                    items: [
                      for (final sport in academy.sports)
                        DropdownMenuItem(
                          value: sport.id,
                          child: Text(sport.name),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        final sport = academy.sports.firstWhere(
                          (s) => s.id == value,
                        );
                        _onSportSelected(sport.id, sport.name);
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCoaches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sports, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Select Coaches',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sport: $_selectedSportName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tick the coaches to assign to this batch.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_loadingCoaches)
          const AppLoading(label: 'Loading coaches...', centered: false)
        else if (_availableCoaches.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.sports_outlined, size: 48, color: scheme.outline),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No coaches found for this sport',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              if (_selectedCoachIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      AppBadge(
                        label: '${_selectedCoachIds.length} selected',
                        icon: Icons.check_circle,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              for (final coach in _availableCoaches)
                _CoachTile(
                  coach: coach,
                  isSelected: _selectedCoachIds.contains(coach.coachId),
                  onTap: () => _toggleCoach(coach.coachId),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildStepAthletes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_run_outlined, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Select Athletes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sport: $_selectedSportName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tick the athletes to assign to this batch.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_loadingAthletes)
          const AppLoading(label: 'Loading athletes...', centered: false)
        else if (_availableAthletes.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.person_outline, size: 48, color: scheme.outline),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No athletes found for this sport',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              if (_selectedAthleteIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      AppBadge(
                        label: '${_selectedAthleteIds.length} selected',
                        icon: Icons.check_circle,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              for (final athlete in _availableAthletes)
                _AthleteTile(
                  athlete: athlete,
                  isSelected: _selectedAthleteIds.contains(athlete.athleteId),
                  onTap: () => _toggleAthlete(athlete.athleteId),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildStepSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.date_range_outlined, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Batch Date Range',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Set the start and end dates for this batch.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DateField(
                      label: 'End Date',
                      date: _endDate,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? _startDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined, color: scheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Schedule Slots',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  AppButton(
                    label: 'Add',
                    icon: Icons.add,
                    expanded: false,
                    onPressed: _addSlot,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add at least one weekly schedule slot.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_slots.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.schedule, size: 48, color: scheme.outline),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No schedule slots yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                for (int i = 0; i < _slots.length; i++)
                  _SlotTile(
                    slot: _slots[i],
                    onDelete: () => setState(() => _slots.removeAt(i)),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _summaryRow('Name', _nameController.text.trim()),
              _summaryRow('Sport', _selectedSportName ?? '—'),
              _summaryRow('Start Date', _startDate != null
                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                  : '—'),
              _summaryRow('End Date', _endDate != null
                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                  : '—'),
              _summaryRow('Coaches', '${_selectedCoachIds.length} selected'),
              _summaryRow('Athletes', '${_selectedAthleteIds.length} selected'),
              _summaryRow('Slots', '${_slots.length} added'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ColorScheme get scheme => Theme.of(context).colorScheme;
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  static const _labels = ['Details', 'Coaches', 'Athletes', 'Schedule'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: i <= currentStep ? scheme.primary : scheme.outlineVariant,
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= currentStep ? scheme.primary : scheme.surfaceContainerHighest,
                      border: Border.all(
                        color: i <= currentStep ? scheme.primary : scheme.outlineVariant,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: i < currentStep
                        ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: i <= currentStep ? scheme.onPrimary : scheme.outline,
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[i],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: i <= currentStep ? scheme.primary : scheme.outline,
                      fontWeight: i == currentStep ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CoachTile extends StatelessWidget {
  const _CoachTile({
    required this.coach,
    required this.isSelected,
    required this.onTap,
  });

  final Coach coach;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primaryContainer.withValues(alpha: 0.25) : scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                activeColor: scheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 16,
                backgroundColor: brand.primaryGradient.colors.first,
                child: Text(
                  _initials(coach.fullName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach.fullName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      coach.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (coach.sports.isNotEmpty)
                AppBadge(
                  label: coach.sports.first.name,
                  icon: Icons.emoji_events_outlined,
                  compact: true,
                ),
            ],
          ),
        ),
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

class _AthleteTile extends StatelessWidget {
  const _AthleteTile({
    required this.athlete,
    required this.isSelected,
    required this.onTap,
  });

  final Athlete athlete;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primaryContainer.withValues(alpha: 0.25) : scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                activeColor: scheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 16,
                backgroundColor: brand.sportGradient.colors.first,
                child: Text(
                  _initials(athlete.fullName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athlete.fullName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      athlete.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (athlete.ageGroup != null)
                AppBadge(
                  label: athlete.ageGroup!,
                  compact: true,
                ),
            ],
          ),
        ),
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateText = date != null
        ? '${date!.day}/${date!.month}/${date!.year}'
        : 'Not set';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              dateText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: date != null ? null : scheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.onDelete});

  final BatchSlotInput slot;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 16, color: scheme.outline),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${slot.dayOfWeek.label} · ${slot.startTime} – ${slot.endTime}'
              '${slot.location != null ? ' · ${slot.location}' : ''}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.close, size: 16, color: scheme.error),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
