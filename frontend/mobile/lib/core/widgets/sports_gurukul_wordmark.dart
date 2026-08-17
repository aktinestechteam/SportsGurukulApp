import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/auth_palette.dart';

/// Two-line typographic SPORTS GURUKUL wordmark.
///
/// No icon, no AppBrand, no logo tile — pure type. "GURUKUL" renders with a
/// stitched stroke + fill so it reads as an outlined 3D letterform.
class SportsGurukulWordmark extends StatelessWidget {
  const SportsGurukulWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SPORTS',
          style: GoogleFonts.barlowCondensed(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            height: 1.0,
            color: isDark ? Colors.white : AuthPalette.lightText,
          ),
        ),
        Stack(
          children: [
            Text(
              'GURUKUL',
              style: GoogleFonts.barlowCondensed(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
                height: 1.0,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.2
                  ..color = AuthPalette.redStroke,
              ),
            ),
            Text(
              'GURUKUL',
              style: GoogleFonts.barlowCondensed(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
                height: 1.0,
                color: AuthPalette.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Single-line wordmark for app headers / toolbars.
///
/// Same letterforms as [SportsGurukulWordmark] (Barlow Condensed, "GURUKUL" in
/// brand red) but on one line so it fits a 64px toolbar.
class SportsGurukulHeaderWordmark extends StatelessWidget {
  const SportsGurukulHeaderWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SPORTS',
            style: GoogleFonts.barlowCondensed(
              fontSize: 24,
              height: 1.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isDark ? Colors.white : AuthPalette.lightText,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'GURUKUL',
            style: GoogleFonts.barlowCondensed(
              fontSize: 24,
              height: 1.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: AuthPalette.red,
            ),
          ),
        ],
      ),
    );
  }
}