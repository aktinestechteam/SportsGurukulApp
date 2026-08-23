import 'package:flutter/material.dart';

import 'app_component_themes.dart';
import 'app_theme_extensions.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF2B3A9B),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE0E3FF),
      onPrimaryContainer: Color(0xFF101A66),
      secondary: Color(0xFF5B4ACB),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFE8E2FF),
      onSecondaryContainer: Color(0xFF1A0D5C),
      tertiary: Color(0xFF0E7490),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFC4F2FF),
      onTertiaryContainer: Color(0xFF002A36),
      error: Color(0xFFC62828),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFF6F7FC),
      onSurface: Color(0xFF171D30),
      surfaceDim: Color(0xFFE7E9F4),
      surfaceBright: Color(0xFFFCFCFF),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFFFFFFF),
      surfaceContainer: Color(0xFFEEF0F9),
      surfaceContainerHigh: Color(0xFFE7EAF6),
      surfaceContainerHighest: Color(0xFFDFE3F2),
      onSurfaceVariant: Color(0xFF4C5570),
      outline: Color(0xFFAEB6CC),
      outlineVariant: Color(0xFFE2E6F2),
      shadow: Color(0xFF0B1220),
      scrim: Color(0xFF0B1220),
      inverseSurface: Color(0xFF2A3250),
      onInverseSurface: Color(0xFFEEF0F9),
      inversePrimary: Color(0xFFC4CBFF),
    );

    final baseText = Typography.material2021(
      platform: TargetPlatform.android,
    ).black;
    final textTheme = AppTypography.apply(baseText);

    return AppComponentThemes.build(
      scheme,
      textTheme,
      Brightness.light,
    ).copyWith(
      extensions: [
        BrandColors.light,
        GlassColors.light,
        StatusColors.light,
        ChartColors.light,
        AmbientColors.light,
      ],
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFA4B1F5),
      onPrimary: Color(0xFF151D66),
      primaryContainer: Color(0xFF2C3AA8),
      onPrimaryContainer: Color(0xFFE3E6FF),
      secondary: Color(0xFFC4BAFC),
      onSecondary: Color(0xFF241A6B),
      secondaryContainer: Color(0xFF3B2E86),
      onSecondaryContainer: Color(0xFFE8E2FF),
      tertiary: Color(0xFF5CC9E4),
      onTertiary: Color(0xFF003745),
      tertiaryContainer: Color(0xFF0B4A5E),
      onTertiaryContainer: Color(0xFFC4F2FF),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF0D1526),
      onSurface: Color(0xFFE7EBF7),
      surfaceDim: Color(0xFF0A1120),
      surfaceBright: Color(0xFF3B4A6B),
      surfaceContainerLowest: Color(0xFF080F1E),
      surfaceContainerLow: Color(0xFF121B2E),
      surfaceContainer: Color(0xFF182236),
      surfaceContainerHigh: Color(0xFF1F2B43),
      surfaceContainerHighest: Color(0xFF27344F),
      onSurfaceVariant: Color(0xFFA6B0CB),
      outline: Color(0xFF6E7C9C),
      outlineVariant: Color(0xFF283551),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE7EBF7),
      onInverseSurface: Color(0xFF1A2338),
      inversePrimary: Color(0xFF2B3A9B),
    );

    final baseText = Typography.material2021(
      platform: TargetPlatform.android,
    ).white;
    final textTheme = AppTypography.apply(baseText);

    return AppComponentThemes.build(
      scheme,
      textTheme,
      Brightness.dark,
    ).copyWith(
      extensions: [
        BrandColors.dark,
        GlassColors.dark,
        StatusColors.dark,
        ChartColors.dark,
        AmbientColors.dark,
      ],
    );
  }
}
