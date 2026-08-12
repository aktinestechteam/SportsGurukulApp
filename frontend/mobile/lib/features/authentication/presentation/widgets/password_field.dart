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
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      icon: Icons.lock_outline,
      obscureText: true,
      obscureTextToggle: true,
      validator: validator,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
    );
  }
}
