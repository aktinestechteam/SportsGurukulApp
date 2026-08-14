import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
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
import '../../domain/entities/coach.dart';
import '../../domain/repositories/coach_repository.dart';
import '../providers/coach_provider.dart';

class AddCoachPage extends StatefulWidget {
  const AddCoachPage({
    super.key,
    required this.academyId,
    this.academy,
    this.coach,
  });

  final String academyId;
  final Academy? academy;
  final Coach? coach;

  bool get isEditing => coach != null;

  @override
  State<AddCoachPage> createState() => _AddCoachPageState();
}

class _AddCoachPageState extends State<AddCoachPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _mobile;

  Academy? _academy;
  String? _selectedBranchId;
  final Set<String> _selectedSportIds = {};
  final Map<String, TextEditingController> _specializationControllers = {};

  bool _loadingFallback = false;

  @override
  void initState() {
    super.initState();
    final editingCoach = widget.coach;

    _firstName = TextEditingController(text: editingCoach?.firstName);
    _lastName = TextEditingController(text: editingCoach?.lastName);
    _email = TextEditingController(text: editingCoach?.email);
    _mobile = TextEditingController(text: editingCoach?.mobileNumber);

    _academy = widget.academy;
    if (_academy == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAcademyFallback();
        }
      });
    } else if (_academy!.branches.isNotEmpty) {
      _selectedBranchId = editingCoach?.branchId ?? _academy!.branches.first.id;
    }

    if (editingCoach != null) {
      for (final sport in editingCoach.sports) {
        _selectedSportIds.add(sport.sportId);
        _specializationControllers[sport.sportId] = TextEditingController(
          text: sport.specialization,
        );
      }
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _mobile.dispose();
    for (final controller in _specializationControllers.values) {
      controller.dispose();
    }
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
        if (_selectedBranchId == null && academy.branches.isNotEmpty) {
          _selectedBranchId = academy.branches.first.id;
        }
      }
    });
  }

  void _toggleSport(String sportId, bool selected) {
    setState(() {
      if (selected) {
        _selectedSportIds.add(sportId);
        _specializationControllers.putIfAbsent(sportId,
            () => TextEditingController());
      } else {
        _selectedSportIds.remove(sportId);
      }
    });
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

    if (_selectedSportIds.isEmpty) {
      AppSnackbar.show(
        context,
        'Select at least one sport for the coach.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final sports = [
      for (final sportId in _selectedSportIds)
        CoachSportInput(
          sportId: sportId,
          specialization: _optional(
            _specializationControllers[sportId]?.text ?? '',
          ),
        ),
    ];

    final input = CoachRequestInput(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      mobileNumber: _mobile.text.trim(),
      branchId: academy.branches.isEmpty ? null : _selectedBranchId,
      sports: sports,
    );

    final provider = context.read<CoachProvider>();
    final editingCoach = widget.coach;
    final success = editingCoach == null
        ? await provider.createCoach(widget.academyId, input)
        : await provider.updateCoach(
            widget.academyId,
            editingCoach.coachId,
            input,
          );

    if (!mounted) return;

    if (success) {
      AppSnackbar.show(
        context,
        editingCoach == null
            ? 'Coach added successfully. Login credentials have been sent to the registered email address.'
            : 'Coach updated successfully.',
        type: AppFeedbackType.success,
      );
      context.pop();
    } else {
      AppSnackbar.show(
        context,
        provider.errorMessage ??
            (editingCoach == null
                ? 'Could not add the coach. Please try again.'
                : 'Could not update the coach. Please try again.'),
        type: AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoachProvider>();
    final academy = _academy;
    final hasBranches = academy != null && academy.branches.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Coach' : 'Add Coach'),
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
                          title: academy?.name ?? 'Coach details',
                          subtitle: widget.isEditing
                              ? 'Update the coach profile, branch and sport assignments.'
                              : 'The coach will receive their sign-in credentials by email.',
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
                                  hintText: 'Coach first name',
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
                                  hintText: 'Coach last name',
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
                                  hintText: 'coach@example.com',
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
                                      'Select the sports this coach will handle.',
                                  spacing: AppSpacing.md,
                                ),
                                if (academy == null || academy.sports.isEmpty)
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                    child: Text(
                                      'No sports configured for this academy yet.',
                                    ),
                                  )
                                else
                                  for (final sport in academy.sports)
                                    _SportTile(
                                      sport: sport,
                                      selected: _selectedSportIds.contains(
                                        sport.id,
                                      ),
                                      specializationController:
                                          _specializationControllers[sport.id],
                                      onChanged: (selected) =>
                                          _toggleSport(sport.id, selected),
                                    ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: widget.isEditing
                                ? 'Save Changes'
                                : 'Add Coach',
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

class _SportTile extends StatelessWidget {
  const _SportTile({
    required this.sport,
    required this.selected,
    required this.onChanged,
    this.specializationController,
  });

  final AcademySport sport;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final TextEditingController? specializationController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          type: MaterialType.transparency,
          child: CheckboxListTile(
            value: selected,
            onChanged: (value) => onChanged(value ?? false),
            title: Text(sport.name),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (selected && specializationController != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.huge,
              bottom: AppSpacing.sm,
            ),
            child: AppTextField(
              controller: specializationController,
              label: 'Specialization (optional)',
              hintText: 'e.g. Batting, Goalkeeping',
              textInputAction: TextInputAction.next,
            ),
          ),
      ],
    );
  }
}

String? _optional(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
