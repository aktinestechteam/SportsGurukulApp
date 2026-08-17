import 'package:flutter/material.dart';

import '../theme/auth_palette.dart';

/// Global enterprise text field. All application forms should use this.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.obscureText = false,
    this.obscureTextToggle = false,
    this.enabled = true,
    this.onChanged,
    this.onFieldSubmitted,
    this.autofillHints,
    this.initialValue,
    this.readOnly = false,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool obscureTextToggle;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final String? initialValue;
  final bool readOnly;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    if (obscureTextToggle) {
      return _ObscurableField(parent: this);
    }
    return _buildField(context);
  }

  Widget _buildField(BuildContext context) {
    final prefixIcon = icon == null ? null : Icon(icon, size: 20);
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      decoration: _decoration(context, prefixIcon: prefixIcon),
    );
  }

  InputDecoration _decoration(BuildContext context, {Widget? prefixIcon}) {
    final scheme = Theme.of(context).colorScheme;
    final radius = const BorderRadius.all(Radius.circular(6));
    final enabledBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AuthPalette.border(context), width: 1),
    );

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AuthPalette.surface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      labelStyle: TextStyle(
        color: AuthPalette.subtitle(context),
        fontSize: 13,
      ),
      hintStyle: TextStyle(
        color: AuthPalette.muted(context),
        fontSize: 13,
      ),
      prefixIconColor: AuthPalette.subtitle(context),
      suffixIconColor: AuthPalette.subtitle(context),
      border: enabledBorder,
      enabledBorder: enabledBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AuthPalette.red, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: AuthPalette.border(context).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      errorStyle: TextStyle(color: scheme.error),
    );
  }
}

class _ObscurableField extends StatefulWidget {
  const _ObscurableField({required this.parent});

  final AppTextField parent;

  @override
  State<_ObscurableField> createState() => _ObscurableFieldState();
}

class _ObscurableFieldState extends State<_ObscurableField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final parent = widget.parent;
    final prefixIcon = parent.icon == null ? null : Icon(parent.icon, size: 20);
    return TextFormField(
      controller: parent.controller,
      initialValue: parent.initialValue,
      obscureText: _obscure,
      enabled: parent.enabled,
      readOnly: parent.readOnly,
      maxLines: parent.maxLines,
      keyboardType: parent.keyboardType,
      textInputAction: parent.textInputAction,
      autofillHints: parent.autofillHints,
      validator: parent.validator,
      onChanged: parent.onChanged,
      onFieldSubmitted: parent.onFieldSubmitted,
      decoration: parent._decoration(context, prefixIcon: prefixIcon).copyWith(
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: AuthPalette.subtitle(context),
          ),
          tooltip: _obscure ? 'Show password' : 'Hide password',
          splashRadius: 18,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}