import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/repositories/academy_repository.dart';

Future<AcademyBranchInput?> showBranchDialog(
  BuildContext context, {
  AcademyBranchInput? initial,
}) {
  return showDialog<AcademyBranchInput>(
    context: context,
    builder: (context) => _BranchDialog(initial: initial),
  );
}

Future<AcademySportInput?> showSportDialog(
  BuildContext context, {
  AcademySportInput? initial,
}) {
  return showDialog<AcademySportInput>(
    context: context,
    builder: (context) => _SportDialog(initial: initial),
  );
}

Future<AcademyFacilityInput?> showFacilityDialog(
  BuildContext context, {
  AcademyFacilityInput? initial,
}) {
  return showDialog<AcademyFacilityInput>(
    context: context,
    builder: (context) => _FacilityDialog(initial: initial),
  );
}

Future<AcademyMembershipInput?> showMembershipDialog(
  BuildContext context, {
  AcademyMembershipInput? initial,
}) {
  return showDialog<AcademyMembershipInput>(
    context: context,
    builder: (context) => _MembershipDialog(initial: initial),
  );
}

abstract class _ItemDialog<T> extends StatefulWidget {
  const _ItemDialog({required this.initial});

  final T? initial;

  String get title;
}

abstract class _ItemDialogState<T, W extends _ItemDialog<T>>
    extends State<W> {
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get controllers;

  String? _required(String? value, {String field = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required.';
    }
    return null;
  }

  String? _requiredName(String? value) => _required(value);

  T? buildResult();

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final result = buildResult();
    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }

  AlertDialog dialog({required Widget content}) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(key: _formKey, child: content),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Save',
          expanded: false,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _BranchDialog extends _ItemDialog<AcademyBranchInput> {
  const _BranchDialog({super.initial});

  @override
  String get title => 'Add Branch';

  @override
  State<_BranchDialog> createState() => _BranchDialogState();
}

class _BranchDialogState extends _ItemDialogState<
    AcademyBranchInput, _BranchDialog> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _address = TextEditingController(text: widget.initial?.address);
  late final _city = TextEditingController(text: widget.initial?.city);
  late final _state = TextEditingController(text: widget.initial?.state);
  late final _country = TextEditingController(text: widget.initial?.country);
  late final _postal = TextEditingController(text: widget.initial?.postalCode);
  late final _email = TextEditingController(text: widget.initial?.contactEmail);
  late final _phone = TextEditingController(text: widget.initial?.contactPhone);
  late bool _isMain = widget.initial?.isMain ?? false;

  @override
  List<TextEditingController> get controllers => [
    _name,
    _address,
    _city,
    _state,
    _country,
    _postal,
    _email,
    _phone,
  ];

  @override
  AcademyBranchInput? buildResult() {
    return AcademyBranchInput(
      name: _name.text.trim(),
      address: _optional(_address.text),
      city: _optional(_city.text),
      state: _optional(_state.text),
      country: _optional(_country.text),
      postalCode: _optional(_postal.text),
      contactEmail: _optional(_email.text),
      contactPhone: _optional(_phone.text),
      isMain: _isMain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return dialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _name,
            label: 'Branch Name',
            icon: Icons.business_outlined,
            textInputAction: TextInputAction.next,
            validator: _requiredName,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _address,
            label: 'Address',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _city,
            label: 'City',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _state,
            label: 'State',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _country,
            label: 'Country',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _postal,
            label: 'Postal Code',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _email,
            label: 'Contact Email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _phone,
            label: 'Contact Phone',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.xs),
          SwitchListTile(
            value: _isMain,
            onChanged: (v) => setState(() => _isMain = v),
            title: const Text('Main Branch'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}

class _SportDialog extends _ItemDialog<AcademySportInput> {
  const _SportDialog({super.initial});

  @override
  String get title => 'Add Sport';

  @override
  State<_SportDialog> createState() => _SportDialogState();
}

class _SportDialogState extends _ItemDialogState<AcademySportInput, _SportDialog> {
  late final _name = TextEditingController(text: widget.initial?.name);

  @override
  List<TextEditingController> get controllers => [_name];

  @override
  AcademySportInput? buildResult() {
    return AcademySportInput(name: _name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return dialog(
      content: AppTextField(
        controller: _name,
        label: 'Sport Name',
        icon: Icons.sports_outlined,
        textInputAction: TextInputAction.done,
        validator: _requiredName,
      ),
    );
  }
}

class _FacilityDialog extends _ItemDialog<AcademyFacilityInput> {
  const _FacilityDialog({super.initial});

  @override
  String get title => 'Add Facility';

  @override
  State<_FacilityDialog> createState() => _FacilityDialogState();
}

class _FacilityDialogState extends _ItemDialogState<
    AcademyFacilityInput, _FacilityDialog> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _type = TextEditingController(text: widget.initial?.type);
  late final _capacity = TextEditingController(
    text: widget.initial?.capacity?.toString(),
  );
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );

  @override
  List<TextEditingController> get controllers => [
    _name,
    _type,
    _capacity,
    _description,
  ];

  @override
  AcademyFacilityInput? buildResult() {
    return AcademyFacilityInput(
      name: _name.text.trim(),
      type: _optional(_type.text),
      capacity: int.tryParse(_capacity.text.trim()),
      description: _optional(_description.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return dialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _name,
            label: 'Facility Name',
            icon: Icons.location_city_outlined,
            textInputAction: TextInputAction.next,
            validator: _requiredName,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _type,
            label: 'Type (e.g. Ground, Indoor)',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _capacity,
            label: 'Capacity',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _description,
            label: 'Description',
            maxLines: 2,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

class _MembershipDialog extends _ItemDialog<AcademyMembershipInput> {
  const _MembershipDialog({super.initial});

  @override
  String get title => 'Add Membership';

  @override
  State<_MembershipDialog> createState() => _MembershipDialogState();
}

class _MembershipDialogState extends _ItemDialogState<
    AcademyMembershipInput, _MembershipDialog> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );
  late final _duration = TextEditingController(
    text: (widget.initial?.durationDays ?? 30).toString(),
  );
  late final _price = TextEditingController(
    text: (widget.initial?.price ?? 0).toStringAsFixed(2),
  );

  @override
  List<TextEditingController> get controllers => [
    _name,
    _description,
    _duration,
    _price,
  ];

  @override
  AcademyMembershipInput? buildResult() {
    return AcademyMembershipInput(
      name: _name.text.trim(),
      description: _optional(_description.text),
      durationDays: int.tryParse(_duration.text.trim()) ?? 0,
      price: double.tryParse(_price.text.trim()) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return dialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _name,
            label: 'Membership Name',
            icon: Icons.card_membership_outlined,
            textInputAction: TextInputAction.next,
            validator: _requiredName,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _description,
            label: 'Description',
            maxLines: 2,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _duration,
            label: 'Duration (days)',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Duration is required.';
              }
              if ((int.tryParse(value.trim()) ?? 0) <= 0) {
                return 'Duration must be greater than zero.';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _price,
            label: 'Price',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

String? _optional(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
