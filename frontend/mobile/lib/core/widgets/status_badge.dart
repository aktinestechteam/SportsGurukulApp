import 'package:flutter/material.dart';

import '../theme/app_theme_extensions.dart';
import 'app_badge.dart';

/// Maps known SPORTSGURUKUL statuses to themed colors/icons.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.unknownLabel = 'Unknown',
  });

  final String status;
  final String unknownLabel;

  @override
  Widget build(BuildContext context) {
    final colors = StatusColors.of(context);
    final (label, bg, fg, icon) = _resolve(status, colors);

    return AppBadge(
      label: label,
      backgroundColor: bg,
      foregroundColor: fg,
      icon: icon,
    );
  }

  (String, Color, Color, IconData?) _resolve(String raw, StatusColors colors) {
    final key = raw.trim().toLowerCase().replaceAll(' ', '');
    return switch (key) {
      'active' => (
        raw,
        colors.successContainer,
        colors.success,
        Icons.check_circle_outline,
      ),
      'appuser' => (
        raw,
        colors.infoContainer,
        colors.info,
        Icons.person_outline,
      ),
      'suspended' => (
        raw,
        colors.warningContainer,
        colors.warning,
        Icons.pause_circle_outline,
      ),
      'deactivated' => (
        raw,
        colors.warningContainer,
        colors.warning,
        Icons.pause_circle_outline,
      ),
      'locked' => (
        raw,
        colors.errorContainer,
        colors.error,
        Icons.lock_outline,
      ),
      'inactive' => (
        raw,
        colors.warningContainer,
        colors.warning,
        Icons.radio_button_unchecked,
      ),
      'pending' => (
        raw,
        colors.warningContainer,
        colors.warning,
        Icons.hourglass_empty,
      ),
      'approved' => (
        raw,
        colors.successContainer,
        colors.success,
        Icons.verified_outlined,
      ),
      'rejected' => (
        raw,
        colors.errorContainer,
        colors.error,
        Icons.cancel_outlined,
      ),
      'completed' => (
        raw,
        colors.successContainer,
        colors.success,
        Icons.check_circle_outline,
      ),
      'draft' => (raw, colors.infoContainer, colors.info, Icons.edit_outlined),
      'inprogress' => (raw, colors.infoContainer, colors.info, Icons.timelapse),
      'coach' => (
        raw,
        colors.infoContainer,
        colors.info,
        Icons.sports_outlined,
      ),
      'athlete' => (
        raw,
        colors.successContainer,
        colors.success,
        Icons.directions_run,
      ),
      _ => (
        raw.isEmpty ? unknownLabel : raw,
        colors.warningContainer,
        colors.warning,
        Icons.help_outline,
      ),
    };
  }
}
