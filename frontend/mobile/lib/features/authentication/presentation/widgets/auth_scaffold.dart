import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/sports_gurukul_wordmark.dart';

/// Disciplined authentication layout.
///
/// A 3px primary stripe runs the full width along the very top. Below it the
/// brand zone and form zone are stacked and centered vertically in the
/// remaining space, with a thin divider between them. The form is constrained
/// to 440px and centered on wider screens. No gradients, orbs, glows or
/// elevated cards.
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
    final minHeight = MediaQuery.of(context).size.height - 3;

    return Scaffold(
      backgroundColor: AuthPalette.bg(context),
      body: Column(
        children: [
          Container(
            height: 3,
            color: AuthPalette.red,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: Column(
                          children: [
                            const SportsGurukulWordmark(),
                            const SizedBox(height: 8),
                            Text(
                              'TRAIN  ·  COMPETE  ·  EXCEL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3.0,
                                color: AuthPalette.muted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: AuthPalette.divider(context),
                        height: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  title.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.barlowCondensed(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: AuthPalette.textPrimary(context),
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    subtitle!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AuthPalette.subtitle(context),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                child,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}