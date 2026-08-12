import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

enum AppCardVariant {
  standard,
  tonal,
  glass,
  brand,
  warning,
  success,
  interactive,
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.standard,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);

    if (variant == AppCardVariant.brand) {
      return _BrandCard(
        padding: padding,
        onTap: onTap,
        radius: AppRadii.br(AppRadii.large),
        child: child,
      );
    }

    final (backgroundColor, borderColor, shadow) = switch (variant) {
      AppCardVariant.standard => (
        color ?? scheme.surfaceContainerLow,
        scheme.outlineVariant,
        AppShadows.subtle,
      ),
      AppCardVariant.tonal => (
        color ?? scheme.secondaryContainer.withValues(alpha: 0.4),
        Colors.transparent,
        AppShadows.none,
      ),
      AppCardVariant.glass => (
        color ?? GlassColors.of(context).background,
        GlassColors.of(context).border,
        AppShadows.small,
      ),
      AppCardVariant.warning => (
        color ?? status.warningContainer.withValues(alpha: 0.5),
        Colors.transparent,
        AppShadows.none,
      ),
      AppCardVariant.success => (
        color ?? status.successContainer.withValues(alpha: 0.5),
        Colors.transparent,
        AppShadows.none,
      ),
      AppCardVariant.interactive => (
        color ?? scheme.surfaceContainerLow,
        scheme.outlineVariant,
        AppShadows.small,
      ),
      AppCardVariant.brand => (
        Colors.transparent,
        Colors.transparent,
        AppShadows.none,
      ),
    };

    final content = _CardSurface(
      padding: padding,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      shadow: shadow,
      radius: AppRadii.br(AppRadii.large),
      interactive: onTap != null,
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.br(AppRadii.large),
        child: content,
      ),
    );
  }
}

/// Renders a card surface with a subtle hover lift when [interactive].
class _CardSurface extends StatefulWidget {
  const _CardSurface({
    required this.padding,
    required this.backgroundColor,
    required this.borderColor,
    required this.shadow,
    required this.radius,
    required this.interactive,
    required this.child,
  });

  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final List<BoxShadow> shadow;
  final BorderRadius radius;
  final bool interactive;
  final Widget child;

  @override
  State<_CardSurface> createState() => _CardSurfaceState();
}

class _CardSurfaceState extends State<_CardSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lifted = widget.interactive && _hovered;

    return MouseRegion(
      cursor: widget.interactive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.standard,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: widget.radius,
          border: Border.all(
            color: lifted
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
                : widget.borderColor,
          ),
          boxShadow: lifted ? AppShadows.hover : widget.shadow,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Brand-gradient card. Text placed on top uses [AppCard.brandForeground].
class _BrandCard extends StatelessWidget {
  const _BrandCard({
    required this.child,
    required this.padding,
    required this.radius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);

    final card = Container(
      decoration: BoxDecoration(
        gradient: brand.primaryGradient,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: brand.indigoA.withValues(alpha: 0.38),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -50,
            child: _Glow(
              color: Colors.white.withValues(alpha: 0.10),
              size: 200,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _Glow(
              color: Colors.white.withValues(alpha: 0.06),
              size: 240,
            ),
          ),
          Positioned(
            top: 1,
            left: 32,
            right: 32,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: AppColors.onBrand),
              child: child,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: radius, child: card),
    );
  }
}

/// Soft radial highlight used for decorative card glows.
class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

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
