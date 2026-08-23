import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radii.dart';

/// Lightweight skeleton primitives used for loading states.
///
/// Uses a subtle opacity pulse (not a full shimmer pass) to stay cheap on
/// low-end devices while still signalling "content is loading".
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius,
    this.color,
    this.circle = false,
  });

  final double width;
  final double height;
  final double? radius;
  final Color? color;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = color ?? scheme.surfaceContainerHighest;

    return _Pulse(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle
              ? null
              : BorderRadius.circular(radius ?? AppRadii.small),
        ),
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.45,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// A skeleton card that mirrors the [AppCard] silhouette.
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({
    super.key,
    this.height,
    this.padding = const EdgeInsets.all(20),
  });

  final double? height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: AppRadii.brLarge,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 140, height: 14),
          SizedBox(height: 16),
          AppSkeleton(height: 16),
          SizedBox(height: 8),
          AppSkeleton(width: 220, height: 16),
          SizedBox(height: 20),
          Row(
            children: [
              AppSkeleton(width: 80, height: 12),
              Spacer(),
              AppSkeleton(width: 60, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// A skeleton list tile that mirrors a [ListTile] with leading avatar.
class AppSkeletonListTile extends StatelessWidget {
  const AppSkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AppSkeleton(circle: true, width: 40, height: 40),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 160, height: 14),
              SizedBox(height: 8),
              AppSkeleton(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

/// A skeleton text block of one or more lines.
class AppSkeletonText extends StatelessWidget {
  const AppSkeletonText({super.key, this.lines = 1, this.lastWidth = 0.6});

  final int lines;
  final double lastWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: isLast ? lastWidth : 1,
            child: const AppSkeleton(height: 14),
          ),
        );
      }),
    );
  }
}
