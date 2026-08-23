import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme_extensions.dart';

/// Premium metric/stat card used on dashboards.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trend,
    this.trendLabel,
    this.accent,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData? icon;
  final double? trend;
  final String? trendLabel;
  final Color? accent;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = accent ?? Theme.of(context).colorScheme.primary;
    final positive = (trend ?? 0) >= 0;
    final status = StatusColors.of(context);

    final trendColor = trend == null
        ? scheme.onSurfaceVariant
        : positive
        ? status.success
        : status.error;

    return _StatCardSurface(
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (icon != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: AppRadii.br(AppRadii.medium),
                  ),
                  child: Icon(icon, size: 20, color: accentColor),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (trend != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  positive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: trendColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${positive ? '+' : ''}${trend!.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (trendLabel != null) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      trendLabel!,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Card surface with a soft accent hairline at the top and a gentle hover
/// lift for a premium dashboard feel.
class _StatCardSurface extends StatefulWidget {
  const _StatCardSurface({
    required this.accentColor,
    required this.child,
  });

  final Color accentColor;
  final Widget child;

  @override
  State<_StatCardSurface> createState() => _StatCardSurfaceState();
}

class _StatCardSurfaceState extends State<_StatCardSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.standard,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadii.brLarge,
          border: Border.all(
            color: _hovered
                ? widget.accentColor.withValues(alpha: 0.35)
                : scheme.outlineVariant,
          ),
          boxShadow: [
            if (_hovered) ...AppShadows.hover,
            BoxShadow(
              color: widget.accentColor.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.accentColor.withValues(alpha: 0.9),
                    widget.accentColor.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
