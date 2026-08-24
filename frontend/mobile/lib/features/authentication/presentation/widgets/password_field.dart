import 'package:flutter/material.dart';

import '../../../../core/widgets/app_text_field.dart';

/// Password input with visibility toggle, backed by [AppTextField].
class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      obscureText: true,
      obscureTextToggle: true,
      validator: validator,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onChanged: onChanged,
    );
  }
}
