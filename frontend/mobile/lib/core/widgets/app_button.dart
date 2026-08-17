import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_motion.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/auth_palette.dart';

enum AppButtonVariant { primary, secondary, outlined, text, destructive }

/// Deep hero-blue used for the secondary "Add" actions.
const Color _spidermanBlue = Color(0xFF1B2A78);

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.expanded = true,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final bool expanded;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final visible = onPressed != null;
    final child = loading ? _spinner(context) : _content(context);

    return AnimatedOpacity(
      duration: AppMotion.fast,
      opacity: visible ? 1 : 0.5,
      child: switch (variant) {
        AppButtonVariant.primary => FilledButton(
          onPressed: enabled ? onPressed : null,
          autofocus: autofocus,
          style: FilledButton.styleFrom(
            backgroundColor: AuthPalette.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: AppRadii.br(6)),
          ),
          child: child,
        ),
        AppButtonVariant.secondary => FilledButton(
          onPressed: enabled ? onPressed : null,
          autofocus: autofocus,
          style: FilledButton.styleFrom(
            backgroundColor: _spidermanBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: AppRadii.br(6)),
          ),
          child: child,
        ),
        AppButtonVariant.outlined => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          autofocus: autofocus,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: AppRadii.br(6)),
          ),
          child: child,
        ),
        AppButtonVariant.text => TextButton(
          onPressed: enabled ? onPressed : null,
          autofocus: autofocus,
          child: child,
        ),
        AppButtonVariant.destructive => FilledButton(
          onPressed: enabled ? onPressed : null,
          autofocus: autofocus,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            shape: RoundedRectangleBorder(borderRadius: AppRadii.br(6)),
          ),
          child: child,
        ),
      },
    );
  }

  Color _labelColor(BuildContext context) {
    return switch (variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.destructive =>
        Theme.of(context).colorScheme.onError,
      AppButtonVariant.secondary => Colors.white,
      _ => Theme.of(context).colorScheme.primary,
    };
  }

  TextStyle _labelStyle(BuildContext context) =>
      GoogleFonts.barlowCondensed(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: _labelColor(context),
      );

  Widget _content(BuildContext context) {
    if (icon == null) {
      return Text(label, style: _labelStyle(context));
    }
    return Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: _labelStyle(context),
          ),
        ),
      ],
    );
  }

  Widget _spinner(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator.adaptive(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(
          switch (variant) {
            AppButtonVariant.primary ||
            AppButtonVariant.secondary ||
            AppButtonVariant.destructive =>
              Colors.white,
            _ => Theme.of(context).colorScheme.primary,
          },
        ),
      ),
    );
  }
}