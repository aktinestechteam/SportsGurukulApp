import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_text_field.dart';

class AcademyDetailsForm extends StatefulWidget {
  const AcademyDetailsForm({
    super.key,
    required this.nameController,
    required this.profileController,
    required this.contactEmailController,
    required this.contactPhoneController,
    required this.addressController,
    required this.cityController,
    required this.stateController,
    required this.countryController,
    required this.postalCodeController,
    required this.logoUrlController,
    required this.isPublic,
    required this.onVisibilityChanged,
  });

  final TextEditingController nameController;
  final TextEditingController profileController;
  final TextEditingController contactEmailController;
  final TextEditingController contactPhoneController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController countryController;
  final TextEditingController postalCodeController;
  final TextEditingController logoUrlController;
  final bool isPublic;
  final ValueChanged<bool> onVisibilityChanged;

  @override
  State<AcademyDetailsForm> createState() => _AcademyDetailsFormState();
}

class _AcademyDetailsFormState extends State<AcademyDetailsForm> {
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Academy name is required.';
    }
    return null;
  }

  String? _validateOptionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final email = value.trim();
    if (!email.contains('@') || email.startsWith('@') || email.endsWith('@')) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(
            title: 'Academy Details',
            subtitle: 'Basic information used to identify your academy',
          ),
          AppTextField(
            controller: widget.nameController,
            label: 'Academy Name',
            icon: Icons.school_outlined,
            textInputAction: TextInputAction.next,
            validator: _validateRequired,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: widget.profileController,
            label: 'Academy Profile / Description',
            icon: Icons.description_outlined,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: widget.contactEmailController,
            label: 'Contact Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateOptionalEmail,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: widget.contactPhoneController,
            label: 'Contact Phone',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: widget.addressController,
            label: 'Address',
            icon: Icons.place_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final city = AppTextField(
                controller: widget.cityController,
                label: 'City',
                textInputAction: TextInputAction.next,
              );
              final state = AppTextField(
                controller: widget.stateController,
                label: 'State',
                textInputAction: TextInputAction.next,
              );
              final country = AppTextField(
                controller: widget.countryController,
                label: 'Country',
                textInputAction: TextInputAction.next,
              );
              final postal = AppTextField(
                controller: widget.postalCodeController,
                label: 'Postal Code',
                textInputAction: TextInputAction.next,
              );

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    city,
                    const SizedBox(height: AppSpacing.md),
                    state,
                    const SizedBox(height: AppSpacing.md),
                    country,
                    const SizedBox(height: AppSpacing.md),
                    postal,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: city),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: state),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: country),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: postal),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: widget.logoUrlController,
            label: 'Logo URL (optional)',
            icon: Icons.image_outlined,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.xs),
          SwitchListTile(
            value: widget.isPublic,
            onChanged: widget.onVisibilityChanged,
            title: const Text('Public Academy'),
            subtitle: const Text(
              'Public academies can be searched when Join Academy launches.',
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}
