import 'package:flutter/material.dart';

import '../theme/app_theme_extensions.dart';

/// Soft, Figma-style ambient surface placed behind content areas.
///
/// Paints a subtle vertical gradient with a few low-alpha glow orbs so large
/// dashboards never feel flat, without distracting from the content itself.
class AppAmbientBackground extends StatelessWidget {
  const AppAmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final ambient = AmbientColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ambient.top, ambient.bottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -160,
            right: -120,
            child: _GlowOrb(color: ambient.orbIndigo, size: 420),
          ),
          Positioned(
            bottom: -200,
            left: -140,
            child: _GlowOrb(color: ambient.orbViolet, size: 460),
          ),
          Positioned(
            top: 420,
            left: -80,
            child: _GlowOrb(color: ambient.orbTeal, size: 300),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
