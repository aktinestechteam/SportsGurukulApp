import 'package:flutter/material.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/app_brand.dart';
import '../../../../core/widgets/glass_container.dart';

/// Premium authentication layout.
///
/// Renders a subtle brand-tinted gradient background with a soft accent glow,
/// the SPORTSGURUKUL brand mark, and a frosted-glass panel around the form on
/// tablet/desktop screens. The glass effect is skipped on phones for
/// performance.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isCompact = AppBreakpoints.isCompact(context);

    final form = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AuthBrandHeader(),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _AuthBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxxl,
                ),
                child: isCompact
                    ? form
                    : GlassContainer(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        constraints: const BoxConstraints(maxWidth: 520),
                        borderRadius: AppRadii.brGlass,
                        child: form,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBrandHeader extends StatelessWidget {
  const _AuthBrandHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const Center(
          child: AppBrand(showWordmark: false, tileSize: 64, iconSize: 40),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'SPORTSGURUKUL',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        Text(
          'Sports · Technology · Intelligence',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ambient = AmbientColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ambient.top, ambient.bottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _AccentOrb(
              colors: [
                scheme.primary.withValues(alpha: 0.14),
                scheme.primary.withValues(alpha: 0),
              ],
            ),
          ),
          Positioned(
            bottom: -160,
            left: -100,
            child: _AccentOrb(
              colors: [
                scheme.secondary.withValues(alpha: 0.10),
                scheme.secondary.withValues(alpha: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentOrb extends StatelessWidget {
  const _AccentOrb({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 340,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}
