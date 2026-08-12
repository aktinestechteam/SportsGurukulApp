import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_theme_extensions.dart';

/// Frosted-glass surface for premium cards, panels and overlays.
///
/// Use sparingly: never on dense tables, long forms or large lists.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.width,
    this.constraints,
    this.showHighlight = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double? width;
  final BoxConstraints? constraints;

  /// Whether to paint a soft light hairline along the top edge.
  final bool showHighlight;

  @override
  Widget build(BuildContext context) {
    final glass = GlassColors.of(context);
    final radius = borderRadius ?? AppRadii.brGlass;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass.blurSigma,
          sigmaY: glass.blurSigma,
        ),
        child: Container(
          width: width,
          constraints: constraints,
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: glass.background,
            borderRadius: radius,
            border: Border.all(color: borderColor ?? glass.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (showHighlight)
                Positioned(
                  top: 1,
                  left: 24,
                  right: 24,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
