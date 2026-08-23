import 'package:flutter/material.dart';

/// Shared color tokens for the authentication experience.
///
/// The auth screens intentionally use a fixed deep blue-grey / cool off-white
/// surface language so the pages read as a single crafted surface rather than
/// layered cards. The single accent color is [red], identical in both modes.
abstract final class AuthPalette {
  // Backgrounds
  static const darkBg = Color(0xFF111318);
  static const darkSurface = Color(0xFF181C24);
  static const darkBorder = Color(0xFF252934);
  static const darkMuted = Color(0xFF444A5A);
  static const darkSubtitle = Color(0xFF5A5F6E);
  static const darkText = Color(0xFFC8CACD);
  static const darkDivider = Color(0xFF1F2229);

  static const lightBg = Color(0xFFF2F3F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFDDE0E6);
  static const lightMuted = Color(0xFFABABAB);
  static const lightSubtitle = Color(0xFF9A9FAB);
  static const lightText = Color(0xFF0D0D0D);
  static const lightDivider = Color(0xFFE2E4E8);

  // Accent — same in both modes
  static const red = Color(0xFFE63946);
  static const redStroke = Color(0xFFFF6B75);
  static const topStripe = Color(0xFFE63946);

  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBg : lightBg;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurface
          : lightSurface;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : lightBorder;

  static Color muted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkMuted : lightMuted;

  static Color subtitle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSubtitle
          : lightSubtitle;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : lightText;

  static Color divider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkDivider : lightDivider;
}