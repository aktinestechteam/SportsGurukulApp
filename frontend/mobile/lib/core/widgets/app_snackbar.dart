import 'package:flutter/material.dart';

import '../theme/app_theme_extensions.dart';

enum AppFeedbackType { success, error, warning, info }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = StatusColors.of(context);
    final (bg, icon, iconColor) = switch (type) {
      AppFeedbackType.success => (
        colors.successContainer,
        Icons.check_circle_outline,
        colors.success,
      ),
      AppFeedbackType.error => (
        colors.errorContainer,
        Icons.error_outline,
        colors.error,
      ),
      AppFeedbackType.warning => (
        colors.warningContainer,
        Icons.warning_amber_outlined,
        colors.warning,
      ),
      AppFeedbackType.info => (
        Theme.of(context).colorScheme.secondaryContainer,
        Icons.info_outline,
        Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    };

    final theme = Theme.of(context);
    final snackBar = SnackBar(
      backgroundColor: bg,
      content: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: iconColor,
              onPressed: onAction ?? () {},
            )
          : null,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
