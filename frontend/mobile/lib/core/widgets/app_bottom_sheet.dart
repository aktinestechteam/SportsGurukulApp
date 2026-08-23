import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// Themed bottom-sheet helper with a consistent drag handle and spacing.
class AppBottomSheet {
  AppBottomSheet._();

  /// Shows a modal bottom sheet built by [builder].
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool showDragHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
      showDragHandle: showDragHandle,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
    );
  }

  /// A generic option-sheet: title + list of [SheetOption]s.
  static Future<T?> showOptions<T>(
    BuildContext context, {
    required String title,
    required List<SheetOption<T>> options,
    String? subtitle,
  }) {
    return show<T>(
      context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xs,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                for (final option in options)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadii.br(AppRadii.medium),
                    ),
                    leading: option.icon == null
                        ? null
                        : Icon(option.icon, color: option.foregroundColor),
                    title: Text(
                      option.label,
                      style: option.foregroundColor == null
                          ? null
                          : TextStyle(color: option.foregroundColor),
                    ),
                    trailing: option.trailing,
                    onTap: () => Navigator.of(context).pop(option.value),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A single selectable row in [AppBottomSheet.showOptions].
class SheetOption<T> {
  const SheetOption({
    required this.label,
    required this.value,
    this.icon,
    this.foregroundColor,
    this.trailing,
  });

  final String label;
  final T value;
  final IconData? icon;
  final Color? foregroundColor;
  final Widget? trailing;
}
