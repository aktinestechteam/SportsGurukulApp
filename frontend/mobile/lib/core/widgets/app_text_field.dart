import 'package:flutter/material.dart';

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
    final prefixIcon = icon == null ? null : Icon(icon, size: 22);
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon,
      ),
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
      decoration: InputDecoration(
        labelText: parent.label,
        hintText: parent.hintText,
        prefixIcon: parent.icon == null ? null : Icon(parent.icon, size: 22),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 22,
          ),
          tooltip: _obscure ? 'Show password' : 'Hide password',
        ),
      ),
    );
  }
}
