import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outlined, text, destructive }

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
          child: child,
        ),
        AppButtonVariant.secondary => FilledButton.tonal(
          onPressed: enabled ? onPressed : null,
          autofocus: autofocus,
          child: child,
        ),
        AppButtonVariant.outlined => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          autofocus: autofocus,
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
            shape: RoundedRectangleBorder(borderRadius: AppRadii.brMedium),
          ),
          child: child,
        ),
      },
    );
  }

  Widget _content(BuildContext context) {
    if (icon == null) {
      return Text(label);
    }
    return Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _spinner(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: switch (variant) {
          AppButtonVariant.primary || AppButtonVariant.destructive => Theme.of(
            context,
          ).colorScheme.onPrimary,
          AppButtonVariant.secondary => Theme.of(
            context,
          ).colorScheme.onSecondaryContainer,
          _ => Theme.of(context).colorScheme.primary,
        },
      ),
    );
  }
}
