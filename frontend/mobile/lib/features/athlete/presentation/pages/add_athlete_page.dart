import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/widgets/app_ambient_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../academy/domain/entities/academy.dart';
import '../../../academy/presentation/providers/academy_provider.dart';
import '../../../authentication/presentation/widgets/validators.dart';
import '../../../coach/domain/entities/coach.dart';
import '../../../coach/presentation/providers/coach_provider.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/repositories/athlete_repository.dart';
import '../providers/athlete_provider.dart';

class AddAthletePage extends StatefulWidget {
  const AddAthletePage({
    super.key,
    required this.academyId,
    this.academy,
    this.athlete,
  });

  final String academyId;
  final Academy? academy;
  final Athlete? athlete;

  bool get isEditing => athlete != null;

  @override
  State<AddAthletePage> createState() => _AddAthletePageState();
}

class _AddAthletePageState extends State<AddAthletePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _mobile;
  late final TextEditingController _address;
  late final TextEditingController _emergencyContact;

  Academy? _academy;
  String? _selectedBranchId;
  AthleteGender _gender = AthleteGender.male;
  DateTime? _dateOfBirth;
  final Set<String> _selectedSportIds = {};

  List<Coach> _academyCoaches = [];
  final Set<String> _selectedCoachIds = {};
  bool _loadingCoaches = false;

  bool _loadingFallback = false;

  @override
  void initState() {
    super.initState();
    final editingAthlete = widget.athlete;

    _firstName = TextEditingController(text: editingAthlete?.firstName);
    _lastName = TextEditingController(text: editingAthlete?.lastName);
    _email = TextEditingController(text: editingAthlete?.email);
    _mobile = TextEditingController(text: editingAthlete?.mobileNumber);
    _address = TextEditingController(text: editingAthlete?.address);
    _emergencyContact = TextEditingController(
      text: editingAthlete?.emergencyContact,
    );

    if (editingAthlete != null) {
      _selectedBranchId = editingAthlete.branchId;
      _gender = editingAthlete.gender;
      _dateOfBirth = editingAthlete.dateOfBirth;
      for (final sport in editingAthlete.sports) {
        _selectedSportIds.add(sport.sportId);
      }
      for (final coach in editingAthlete.mappedCoaches) {
        _selectedCoachIds.add(coach.coachId);
      }
    }

    _academy = widget.academy;
    if (_academy == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAcademyFallback();
        }
      });
    } else {
      _applyAcademyDefaults(_academy!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAcademyCoaches();
      }
    });
  }

  Future<void> _loadAcademyCoaches() async {
    setState(() => _loadingCoaches = true);
    await context.read<CoachProvider>().loadCoaches(widget.academyId);
    if (!mounted) return;
    setState(() {
      _loadingCoaches = false;
      _academyCoaches = context.read<CoachProvider>().coaches;
    });
  }

  void _applyAcademyDefaults(Academy academy) {
    if (academy.branches.isNotEmpty && _selectedBranchId == null) {
      _selectedBranchId = academy.branches.first.id;
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _mobile.dispose();
    _address.dispose();
    _emergencyContact.dispose();
    super.dispose();
  }

  Future<void> _loadAcademyFallback() async {
    setState(() => _loadingFallback = true);
    final academy = await context
        .read<AcademyProvider>()
        .loadAcademy(widget.academyId);
    if (!mounted) return;
    setState(() {
      _loadingFallback = false;
      if (academy != null) {
        _academy = academy;
        _applyAcademyDefaults(academy);
      }
    });
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 12, 1, 1),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Select date of birth',
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  List<Coach> get _filteredCoaches {
    if (_selectedSportIds.isEmpty) return _academyCoaches;
    return _academyCoaches.where((coach) {
      return coach.sports.any(
        (cs) => _selectedSportIds.contains(cs.sportId),
      );
    }).toList();
  }

  Future<void> _submit() async {
    final academy = _academy;
    if (academy == null) {
      AppSnackbar.show(
        context,
        'Academy details are still loading. Please try again.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dob = _dateOfBirth;
    if (dob == null) {
      AppSnackbar.show(
        context,
        'Select the athlete\'s date of birth.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    if (_selectedSportIds.isEmpty) {
      AppSnackbar.show(
        context,
        'Select at least one sport for the athlete.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final input = AthleteRequestInput(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      mobileNumber: _mobile.text.trim(),
      dateOfBirth: dob,
      gender: _gender,
      branchId: academy.branches.isEmpty ? null : _selectedBranchId,
      sportIds: _selectedSportIds.toList(),
      address: _optional(_address.text),
      emergencyContact: _optional(_emergencyContact.text),
      coachIds: _selectedCoachIds.toList(),
    );

    final provider = context.read<AthleteProvider>();
    final editingAthlete = widget.athlete;
    final success = editingAthlete == null
        ? await provider.createAthlete(widget.academyId, input)
        : await provider.updateAthlete(
            widget.academyId,
            editingAthlete.athleteId,
            input,
          );

    if (!mounted) return;

    if (success) {
      context.read<CoachProvider>().loadCoaches(widget.academyId);
      AppSnackbar.show(
        context,
        editingAthlete == null
            ? 'Athlete added successfully. Login credentials have been sent to the registered email address.'
            : 'Athlete updated successfully.',
        type: AppFeedbackType.success,
      );
      context.pop();
    } else {
      AppSnackbar.show(
        context,
        provider.errorMessage ??
            (editingAthlete == null
                ? 'Could not add the athlete. Please try again.'
                : 'Could not update the athlete. Please try again.'),
        type: AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AthleteProvider>();
    final academy = _academy;
    final hasBranches = academy != null && academy.branches.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Athlete' : 'Add Athlete'),
      ),
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
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSectionHeader(
                          title: academy?.name ?? 'Athlete details',
                          subtitle: widget.isEditing
                              ? 'Update the athlete\'s profile and sport assignments.'
                              : 'The athlete will receive their sign-in credentials by email.',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (_loadingFallback)
                          const AppLoading(
                            label: 'Loading academy...',
                            centered: false,
                          )
                        else ...[
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppSectionHeader(
                                  title: 'Personal information',
                                  spacing: AppSpacing.md,
                                ),
                                AppTextField(
                                  controller: _firstName,
                                  label: 'First name',
                                  hintText: 'Athlete first name',
                                  icon: Icons.person_outline,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) => validateRequired(
                                    value,
                                    field: 'First name',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  controller: _lastName,
                                  label: 'Last name',
                                  hintText: 'Athlete last name',
                                  icon: Icons.person_outline,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) => validateRequired(
                                    value,
                                    field: 'Last name',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  controller: _email,
                                  label: 'Email',
                                  hintText: 'athlete@example.com',
                                  icon: Icons.mail_outline,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: validateEmail,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  controller: _mobile,
                                  label: 'Mobile number',
                                  hintText: '+91 98765 43210',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  validator: validateMobile,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _DateOfBirthField(
                                  dateOfBirth: _dateOfBirth,
                                  onTap: _pickDateOfBirth,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                DropdownButtonFormField<AthleteGender>(
                                  initialValue: _gender,
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                    prefixIcon: Icon(Icons.person_outline),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    for (final gender in AthleteGender.values)
                                      DropdownMenuItem(
                                        value: gender,
                                        child: Text(gender.label),
                                      ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _gender = value ?? AthleteGender.male,
                                  ),
                                ),
                                if (hasBranches) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  _BranchSelector(
                                    branches: academy.branches,
                                    selectedBranchId: _selectedBranchId,
                                    onChanged: (value) => setState(
                                      () => _selectedBranchId = value,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  controller: _address,
                                  label: 'Address (optional)',
                                  hintText: 'Home address',
                                  icon: Icons.home_outlined,
                                  maxLines: 2,
                                  textInputAction: TextInputAction.newline,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  controller: _emergencyContact,
                                  label: 'Emergency contact (optional)',
                                  hintText: '+91 91234 56789',
                                  icon: Icons.emergency_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return null;
                                    }
                                    return validateMobile(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppSectionHeader(
                                  title: 'Sports',
                                  subtitle:
                                      'Select the sports this athlete will play.',
                                  spacing: AppSpacing.md,
                                ),
                                if (academy == null || academy.sports.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppSpacing.sm,
                                    ),
                                    child: Text(
                                      'No sports configured for this academy yet.',
                                    ),
                                  )
                                else
                                  for (final sport in academy.sports)
                                    Material(
                                      type: MaterialType.transparency,
                                      child: CheckboxListTile(
                                        dense: true,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        value: _selectedSportIds.contains(
                                          sport.id,
                                        ),
                                        onChanged: (selected) => setState(() {
                                          if (selected ?? false) {
                                            _selectedSportIds.add(sport.id);
                                          } else {
                                            _selectedSportIds.remove(sport.id);
                                          }
                                        }),
                                        title: Text(sport.name),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppSectionHeader(
                                  title: 'Coaches',
                                  subtitle: _selectedSportIds.isEmpty
                                      ? 'Select at least one sport to see available coaches.'
                                      : 'Coaches who train the selected sports.',
                                  spacing: AppSpacing.md,
                                ),
                                if (_loadingCoaches)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppSpacing.sm,
                                    ),
                                    child: AppLoading(
                                      label: 'Loading coaches...',
                                      centered: false,
                                    ),
                                  )
                                else if (_academyCoaches.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppSpacing.sm,
                                    ),
                                    child: Text(
                                      'No coaches in this academy yet. You can assign coaches later.',
                                    ),
                                  )
                                else ...[
                                  for (final coach in _filteredCoaches)
                                    _CoachTile(
                                      coach: coach,
                                      selectedSportIds: _selectedSportIds,
                                      selected: _selectedCoachIds.contains(
                                        coach.coachId,
                                      ),
                                      onChanged: (selected) => setState(() {
                                        if (selected) {
                                          _selectedCoachIds.add(
                                            coach.coachId,
                                          );
                                        } else {
                                          _selectedCoachIds.remove(
                                            coach.coachId,
                                          );
                                        }
                                      }),
                                    ),
                                  if (_selectedSportIds.isNotEmpty &&
                                      _filteredCoaches.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppSpacing.sm,
                                      ),
                                      child: Text(
                                        'No coaches assigned to the selected sports.',
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: widget.isEditing
                                ? 'Save Changes'
                                : 'Add Athlete',
                            icon: widget.isEditing
                                ? Icons.check
                                : Icons.person_add_alt_1,
                            loading: provider.isSaving,
                            onPressed: _submit,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({required this.dateOfBirth, required this.onTap});

  final DateTime? dateOfBirth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date of birth',
          hintText: 'Select date of birth',
          prefixIcon: Icon(Icons.cake_outlined),
          border: OutlineInputBorder(),
        ),
        child: Text(
          dateOfBirth == null
              ? ''
              : '${dateOfBirth!.day.toString().padLeft(2, '0')}-'
                    '${dateOfBirth!.month.toString().padLeft(2, '0')}-'
                    '${dateOfBirth!.year}',
        ),
      ),
    );
  }
}

class _BranchSelector extends StatelessWidget {
  const _BranchSelector({
    required this.branches,
    required this.selectedBranchId,
    required this.onChanged,
  });

  final List<AcademyBranch> branches;
  final String? selectedBranchId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedBranchId,
      decoration: const InputDecoration(
        labelText: 'Branch',
        hintText: 'Select branch',
        prefixIcon: Icon(Icons.account_tree_outlined),
        border: OutlineInputBorder(),
      ),
      items: [
        for (final branch in branches)
          DropdownMenuItem(value: branch.id, child: Text(branch.name)),
      ],
      onChanged: onChanged,
    );
  }
}

class _CoachTile extends StatelessWidget {
  const _CoachTile({
    required this.coach,
    required this.selectedSportIds,
    required this.selected,
    required this.onChanged,
  });

  final Coach coach;
  final Set<String> selectedSportIds;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final matchingSports = coach.sports
        .where((cs) => selectedSportIds.contains(cs.sportId))
        .map((cs) => cs.name)
        .toList();

    return Material(
      type: MaterialType.transparency,
      child: CheckboxListTile(
        value: selected,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(coach.fullName),
        subtitle: Text(
          matchingSports.isEmpty
              ? coach.sports.map((s) => s.name).join(', ')
              : 'Teaches: ${matchingSports.join(', ')}',
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

String? _optional(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
