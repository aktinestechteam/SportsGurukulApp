import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// SPORTSGURUKUL brand mark (icon in a gradient tile) with optional wordmark.
///
/// Use [header] to render the bare brand mark without any surrounding
/// container, suitable for app headers.
class AppBrand extends StatelessWidget {
  const AppBrand({
    super.key,
    this.showWordmark = true,
    this.iconSize = 40,
    this.tileSize = 56,
    this.compact = false,
    this.header = false,
  });

  final bool showWordmark;
  final double iconSize;
  final double tileSize;
  final bool compact;

  /// Renders the bare brand mark without a container, for app headers.
  final bool header;

  @override
  Widget build(BuildContext context) {
    final mark = header ? _buildHeaderMark(context) : _buildTileMark(context);

    if (!showWordmark) {
      return mark;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SPORTS GURUKUL',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            if (!compact)
              Text(
                'Sports · Technology · Intelligence',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderMark(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Icon(Icons.sports_score, size: iconSize, color: scheme.primary);
  }

  Widget _buildTileMark(BuildContext context) {
    final brand = BrandColors.of(context);
    return Container(
      width: tileSize,
      height: tileSize,
      decoration: BoxDecoration(
        gradient: brand.heroGradient,
        borderRadius: AppRadii.br(AppRadii.large),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: brand.indigoA.withValues(alpha: 0.38),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -tileSize * 0.35,
            right: -tileSize * 0.3,
            child: Container(
              width: tileSize * 1.1,
              height: tileSize * 1.1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Icon(Icons.sports_score, size: iconSize, color: Colors.white),
        ],
      ),
    );
  }
}
