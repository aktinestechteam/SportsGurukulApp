import 'package:flutter/material.dart';

import '../theme/auth_palette.dart';

/// Flat branded page surface.
///
/// Mirrors the auth / dashboard language: a solid [AuthPalette.bg] fill with a
/// 3px brand-red stripe along the top. No gradients, orbs or glow. Content is
/// placed in the [child] below the stripe.
class FlatPage extends StatelessWidget {
  const FlatPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AuthPalette.bg(context),
      child: Column(
        children: [
          Container(height: 3, color: AuthPalette.red),
          Expanded(child: child),
        ],
      ),
    );
  }
}
