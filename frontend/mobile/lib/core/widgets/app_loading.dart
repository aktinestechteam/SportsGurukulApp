import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Branded full-area loading indicator with an optional label.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.label, this.centered = true});

  final String? label;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final spinner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        if (label != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            label!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    if (!centered) {
      return spinner;
    }
    return Center(child: spinner);
  }
}

/// Inline loading row used inside buttons and small actions.
class AppLoadingInline extends StatelessWidget {
  const AppLoadingInline({
    super.key,
    this.size = 22,
    this.strokeWidth = 2.4,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: strokeWidth, color: color),
    );
  }
}
