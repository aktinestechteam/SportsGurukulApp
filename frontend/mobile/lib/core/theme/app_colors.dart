import 'package:flutter/material.dart';

/// SPORTSGURUKUL brand and semantic color constants.
///
/// Prefer [AppColors] for fixed brand values and [BrandColors] (a theme
/// extension) whenever a color must adapt between light and dark mode.
class AppColors {
  AppColors._();

  // Brand
  static const Color deepNavy = Color(0xFF0B1220);
  static const Color indigo = Color(0xFF1A237E);
  static const Color royalBlue = Color(0xFF2B3A9B);
  static const Color indigoBright = Color(0xFF3545C4);
  static const Color violet = Color(0xFF5B4ACB);
  static const Color teal = Color(0xFF0E7490);

  // Neutrals
  static const Color coolWhite = Color(0xFFF4F6FB);
  static const Color slate = Color(0xFF64748B);

  /// Soft lavender used at the top of auth/splash surface gradients.
  static const Color lavender = Color(0xFFEDEBFB);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB26A00);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  // White used on top of brand gradients (always opaque for contrast).
  static const Color onBrand = Color(0xFFFFFFFF);
}

/// Fixed ambient glow colors used by [AppAmbientBackground] and decorative
/// orbs. They are applied with low alpha so they read as soft light, never as
/// saturated color.
class AppGlow {
  AppGlow._();

  static const Color indigo = Color(0xFF6370FF);
  static const Color violet = Color(0xFF8E6BFF);
  static const Color royal = Color(0xFF4257E0);
  static const Color teal = Color(0xFF2CC5E8);
}

/// Fixed brand gradients. Use the theme extension [BrandColors] when the
/// gradient needs to adapt to light/dark mode.
class AppGradients {
  AppGradients._();

  /// Primary brand sweep: indigo -> royal blue.
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.indigo, AppColors.royalBlue],
  );

  /// Hero sweep: indigo -> violet (splash, auth accents).
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.indigo, AppColors.violet],
  );

  /// Sport-tech accent: royal blue -> teal (stats, highlights).
  static const LinearGradient sport = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.royalBlue, AppColors.teal],
  );

  /// Very subtle surface tint used behind auth pages.
  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEDEAFB), Color(0xFFF6F6FB)],
  );
}
