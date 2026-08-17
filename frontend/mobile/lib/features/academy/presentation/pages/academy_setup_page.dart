import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/flat_page.dart';
import '../../domain/entities/academy.dart';
import '../../domain/repositories/academy_repository.dart';
import '../providers/academy_provider.dart';
import '../widgets/academy_details_form.dart';
import '../widgets/item_form_dialogs.dart';
import '../widgets/list_editor.dart';
import '../widgets/working_hours_editor.dart';

class AcademySetupPage extends StatefulWidget {
  const AcademySetupPage({super.key, this.academyId});

  final String? academyId;

  @override
  State<AcademySetupPage> createState() => _AcademySetupPageState();
}

class _AcademySetupPageState extends State<AcademySetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _profileController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _logoUrlController = TextEditingController();

  bool _isPublic = false;
  bool _loading = false;
  bool _editMode = false;
  bool _submitting = false;

  List<AcademyBranchInput> _branches = [];
  List<AcademySportInput> _sports = [];
  List<AcademyFacilityInput> _facilities = [];
  List<AcademyMembershipInput> _memberships = [];
  List<AcademyWorkingHourInput> _workingHours = defaultWorkingHours();

  @override
  void initState() {
    super.initState();
    _editMode = widget.academyId != null;
    if (_editMode) {
      _loadAcademy();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _profileController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadAcademy() async {
    setState(() => _loading = true);
    final provider = context.read<AcademyProvider>();
    final academy = await provider.loadAcademy(widget.academyId!);
    if (!mounted) {
      return;
    }
    if (academy == null) {
      AppSnackbar.show(
        context,
        provider.errorMessage ?? 'Unable to load the academy.',
        type: AppFeedbackType.error,
      );
      context.pop();
      return;
    }
    setState(() {
      _loading = false;
      _populate(academy);
    });
  }

  void _populate(Academy academy) {
    _nameController.text = academy.name;
    _profileController.text = academy.profile ?? '';
    _contactEmailController.text = academy.contactEmail ?? '';
    _contactPhoneController.text = academy.contactPhone ?? '';
    _addressController.text = academy.address ?? '';
    _cityController.text = academy.city ?? '';
    _stateController.text = academy.state ?? '';
    _countryController.text = academy.country ?? '';
    _postalCodeController.text = academy.postalCode ?? '';
    _logoUrlController.text = academy.logoUrl ?? '';
    _isPublic = academy.isPublic;

    _branches = academy.branches
        .map(
          (b) => AcademyBranchInput(
            name: b.name,
            address: b.address,
            city: b.city,
            state: b.state,
            country: b.country,
            postalCode: b.postalCode,
            contactEmail: b.contactEmail,
            contactPhone: b.contactPhone,
            isMain: b.isMain,
          ),
        )
        .toList();

    _sports = academy.sports
        .map((s) => AcademySportInput(name: s.name))
        .toList();

    _facilities = academy.facilities
        .map(
          (f) => AcademyFacilityInput(
            name: f.name,
            type: f.type,
            capacity: f.capacity,
            description: f.description,
          ),
        )
        .toList();

    _memberships = academy.memberships
        .map(
          (m) => AcademyMembershipInput(
            name: m.name,
            description: m.description,
            durationDays: m.durationDays,
            price: m.price,
          ),
        )
        .toList();

    _workingHours = completeWorkingHours(
      academy.workingHours
          .map(
            (w) => AcademyWorkingHourInput(
              dayOfWeek: w.dayOfWeek,
              openTime: w.openTime,
              closeTime: w.closeTime,
              isClosed: w.isClosed,
            ),
          )
          .toList(),
    );
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    _submitting = true;
    try {
      FocusScope.of(context).unfocus();
      if (!_formKey.currentState!.validate()) {
        return;
      }

      final provider = context.read<AcademyProvider>();
      final input = AcademyRequestInput(
        name: _nameController.text.trim(),
        profile: _optional(_profileController.text),
        contactEmail: _optional(_contactEmailController.text),
        contactPhone: _optional(_contactPhoneController.text),
        address: _optional(_addressController.text),
        city: _optional(_cityController.text),
        state: _optional(_stateController.text),
        country: _optional(_countryController.text),
        postalCode: _optional(_postalCodeController.text),
        logoUrl: _optional(_logoUrlController.text),
        isPublic: _isPublic,
        branches: _branches,
        sports: _sports,
        facilities: _facilities,
        memberships: _memberships,
        workingHours: completeWorkingHours(_workingHours),
      );

      final success = _editMode
          ? await provider.updateAcademy(widget.academyId!, input)
          : await provider.createAcademy(input);

      if (!mounted) {
        return;
      }

      if (success) {
        AppSnackbar.show(
          context,
          _editMode
              ? 'Academy updated successfully.'
              : 'Academy registered successfully.',
          type: AppFeedbackType.success,
        );
        context.pop();
      } else {
        AppSnackbar.show(
          context,
          provider.errorMessage ?? 'Something went wrong. Please try again.',
          type: AppFeedbackType.error,
        );
      }
    } finally {
      _submitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<AcademyProvider>().isSaving;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editMode ? 'Edit Academy' : 'Register Academy'),
      ),
      body: _loading
          ? const AppLoading(label: 'Loading academy...')
          : FlatPage(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                      padding: AppBreakpoints.horizontalPadding(
                        context,
                      ).add(const EdgeInsets.symmetric(vertical: AppSpacing.xl)),
                      child: AppBreakpoints.constrain(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AcademyDetailsForm(
                                nameController: _nameController,
                                profileController: _profileController,
                                contactEmailController: _contactEmailController,
                                contactPhoneController: _contactPhoneController,
                                addressController: _addressController,
                                cityController: _cityController,
                                stateController: _stateController,
                                countryController: _countryController,
                                postalCodeController: _postalCodeController,
                                logoUrlController: _logoUrlController,
                                isPublic: _isPublic,
                                onVisibilityChanged: (value) =>
                                    setState(() => _isPublic = value),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              _branchesEditor(),
                              const SizedBox(height: AppSpacing.xl),
                              _sportsEditor(),
                              const SizedBox(height: AppSpacing.xl),
                              _facilitiesEditor(),
                              const SizedBox(height: AppSpacing.xl),
                              _membershipsEditor(),
                              const SizedBox(height: AppSpacing.xl),
                              WorkingHoursEditor(
                                hours: _workingHours,
                                onChanged: (value) =>
                                    setState(() => _workingHours = value),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              AppButton(
                                label: _editMode
                                    ? 'Save Changes'
                                    : 'Register Academy',
                                icon: _editMode
                                    ? Icons.save_outlined
                                    : Icons.add_business_outlined,
                                loading: isSaving,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
    );
  }

  Widget _branchesEditor() {
    return ListEditor<AcademyBranchInput>(
      title: 'Branches',
      subtitle: 'Configure the branches belonging to the academy',
      icon: Icons.business_outlined,
      addLabel: 'Add Branch',
      items: [
        for (final b in _branches)
          ListEditorItem(
            title: b.name,
            subtitle: [
              if (b.isMain) 'Main Branch',
              b.city,
            ].where((e) => e != null && e.isNotEmpty).join(' · '),
            value: b,
          ),
      ],
      onAdd: () => _addBranch(),
      onEdit: (b) => _editBranch(b),
      onRemove: (b) => setState(() => _branches.remove(b)),
    );
  }

  Future<void> _addBranch() async {
    final branch = await showBranchDialog(context);
    if (branch != null) {
      setState(() => _branches = [..._branches, branch]);
    }
  }

  Future<void> _editBranch(AcademyBranchInput branch) async {
    final updated = await showBranchDialog(context, initial: branch);
    if (updated != null) {
      setState(() {
        _branches = [
          for (final b in _branches) identical(b, branch) ? updated : b,
        ];
      });
    }
  }

  Widget _sportsEditor() {
    return ListEditor<AcademySportInput>(
      title: 'Sports',
      subtitle: 'Sports offered by the academy',
      icon: Icons.sports_outlined,
      addLabel: 'Add Sport',
      items: [
        for (final s in _sports)
          ListEditorItem(title: s.name, value: s),
      ],
      onAdd: () => _addSport(),
      onEdit: (s) => _editSport(s),
      onRemove: (s) => setState(() => _sports.remove(s)),
    );
  }

  Future<void> _addSport() async {
    final sport = await showSportDialog(context);
    if (sport != null) {
      setState(() => _sports = [..._sports, sport]);
    }
  }

  Future<void> _editSport(AcademySportInput sport) async {
    final updated = await showSportDialog(context, initial: sport);
    if (updated != null) {
      setState(() {
        _sports = [
          for (final s in _sports) identical(s, sport) ? updated : s,
        ];
      });
    }
  }

  Widget _facilitiesEditor() {
    return ListEditor<AcademyFacilityInput>(
      title: 'Facilities',
      subtitle: 'Facilities and resources available at the academy',
      icon: Icons.location_city_outlined,
      addLabel: 'Add Facility',
      items: [
        for (final f in _facilities)
          ListEditorItem(
            title: f.name,
            subtitle: [
              f.type,
              if (f.capacity != null) 'Capacity: ${f.capacity}',
            ].where((e) => e != null && e.isNotEmpty).join(' · '),
            value: f,
          ),
      ],
      onAdd: () => _addFacility(),
      onEdit: (f) => _editFacility(f),
      onRemove: (f) => setState(() => _facilities.remove(f)),
    );
  }

  Future<void> _addFacility() async {
    final facility = await showFacilityDialog(context);
    if (facility != null) {
      setState(() => _facilities = [..._facilities, facility]);
    }
  }

  Future<void> _editFacility(AcademyFacilityInput facility) async {
    final updated = await showFacilityDialog(context, initial: facility);
    if (updated != null) {
      setState(() {
        _facilities = [
          for (final f in _facilities) identical(f, facility) ? updated : f,
        ];
      });
    }
  }

  Widget _membershipsEditor() {
    return ListEditor<AcademyMembershipInput>(
      title: 'Memberships',
      subtitle: 'Membership plans offered by the academy',
      icon: Icons.card_membership_outlined,
      addLabel: 'Add Membership',
      items: [
        for (final m in _memberships)
          ListEditorItem(
            title: m.name,
            subtitle: [
              '${m.durationDays} days',
              m.price > 0 ? '\$${m.price.toStringAsFixed(2)}' : 'Free',
            ].join(' · '),
            value: m,
          ),
      ],
      onAdd: () => _addMembership(),
      onEdit: (m) => _editMembership(m),
      onRemove: (m) => setState(() => _memberships.remove(m)),
    );
  }

  Future<void> _addMembership() async {
    final membership = await showMembershipDialog(context);
    if (membership != null) {
      setState(() => _memberships = [..._memberships, membership]);
    }
  }

  Future<void> _editMembership(AcademyMembershipInput membership) async {
    final updated = await showMembershipDialog(context, initial: membership);
    if (updated != null) {
      setState(() {
        _memberships = [
          for (final m in _memberships)
            identical(m, membership) ? updated : m,
        ];
      });
    }
  }
}

String? _optional(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
