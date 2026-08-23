import 'package:flutter/material.dart';

const _indigoA = Color(0xFF1A237E);
const _indigoB = Color(0xFF2B3A9B);
const _indigoBright = Color(0xFF3545C4);
const _royal = Color(0xFF3949AB);
const _violet = Color(0xFF5B4ACB);
const _teal = Color(0xFF0E7490);

@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.indigoA,
    required this.indigoB,
    required this.royal,
    required this.violet,
    required this.teal,
  });

  final Color indigoA;
  final Color indigoB;
  final Color royal;
  final Color violet;
  final Color teal;

  static const BrandColors light = BrandColors(
    indigoA: _indigoA,
    indigoB: _indigoB,
    royal: _royal,
    violet: _violet,
    teal: _teal,
  );

  static const BrandColors dark = BrandColors(
    indigoA: Color(0xFF28369B),
    indigoB: Color(0xFF3545C4),
    royal: Color(0xFF4052CF),
    violet: Color(0xFF5B4ACB),
    teal: Color(0xFF3BC0E2),
  );

  LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      indigoA,
      indigoB,
      violet.withValues(alpha: 0.9),
    ],
  );

  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      indigoA,
      _indigoBright,
      violet,
    ],
  );

  LinearGradient get sportGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [royal, teal],
  );

  LinearGradient get subtleGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigoA.withValues(alpha: 0.08), violet.withValues(alpha: 0.08)],
  );

  static BrandColors of(BuildContext context) =>
      Theme.of(context).extension<BrandColors>()!;

  @override
  BrandColors copyWith({
    Color? indigoA,
    Color? indigoB,
    Color? royal,
    Color? violet,
    Color? teal,
  }) {
    return BrandColors(
      indigoA: indigoA ?? this.indigoA,
      indigoB: indigoB ?? this.indigoB,
      royal: royal ?? this.royal,
      violet: violet ?? this.violet,
      teal: teal ?? this.teal,
    );
  }

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) {
      return this;
    }
    return BrandColors(
      indigoA: Color.lerp(indigoA, other.indigoA, t)!,
      indigoB: Color.lerp(indigoB, other.indigoB, t)!,
      royal: Color.lerp(royal, other.royal, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
    );
  }
}

@immutable
class GlassColors extends ThemeExtension<GlassColors> {
  const GlassColors({
    required this.background,
    required this.border,
    required this.highlight,
    required this.blurSigma,
  });

  final Color background;
  final Color border;
  final Color highlight;
  final double blurSigma;

  static const GlassColors light = GlassColors(
    background: Color(0xB8FFFFFF),
    border: Color(0x59FFFFFF),
    highlight: Color(0x3DFFFFFF),
    blurSigma: 18,
  );

  static const GlassColors dark = GlassColors(
    background: Color(0x8C101A30),
    border: Color(0x33FFFFFF),
    highlight: Color(0x14FFFFFF),
    blurSigma: 18,
  );

  static GlassColors of(BuildContext context) =>
      Theme.of(context).extension<GlassColors>()!;

  @override
  GlassColors copyWith({
    Color? background,
    Color? border,
    Color? highlight,
    double? blurSigma,
  }) {
    return GlassColors(
      background: background ?? this.background,
      border: border ?? this.border,
      highlight: highlight ?? this.highlight,
      blurSigma: blurSigma ?? this.blurSigma,
    );
  }

  @override
  GlassColors lerp(ThemeExtension<GlassColors>? other, double t) {
    if (other is! GlassColors) {
      return this;
    }
    return GlassColors(
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      blurSigma: blurSigma + (other.blurSigma - blurSigma) * t,
    );
  }
}

@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.error,
    required this.errorContainer,
    required this.info,
    required this.infoContainer,
  });

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final Color info;
  final Color infoContainer;

  static const StatusColors light = StatusColors(
    success: Color(0xFF2E7D32),
    successContainer: Color(0xFFDDF3DF),
    warning: Color(0xFFB26A00),
    warningContainer: Color(0xFFFFE9C7),
    error: Color(0xFFC62828),
    errorContainer: Color(0xFFFFDAD6),
    info: Color(0xFF1565C0),
    infoContainer: Color(0xFFD7E9FF),
  );

  static const StatusColors dark = StatusColors(
    success: Color(0xFF81C784),
    successContainer: Color(0xFF1E4620),
    warning: Color(0xFFFFB74D),
    warningContainer: Color(0xFF4E3800),
    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF93000A),
    info: Color(0xFF90CAF9),
    infoContainer: Color(0xFF0B3D73),
  );

  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>()!;

  @override
  StatusColors copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? error,
    Color? errorContainer,
    Color? info,
    Color? infoContainer,
  }) {
    return StatusColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) {
      return this;
    }
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}

@immutable
class ChartColors extends ThemeExtension<ChartColors> {
  const ChartColors({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.neutral,
  });

  final Color primary;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color neutral;

  List<Color> get series => [primary, secondary, info, success, warning, error];

  static const ChartColors light = ChartColors(
    primary: _indigoB,
    secondary: _violet,
    success: Color(0xFF2E7D32),
    warning: Color(0xFFB26A00),
    error: Color(0xFFC62828),
    info: _teal,
    neutral: Color(0xFF90A4AE),
  );

  static const ChartColors dark = ChartColors(
    primary: Color(0xFFA5B4FC),
    secondary: Color(0xFFC9BFFF),
    success: Color(0xFF81C784),
    warning: Color(0xFFFFB74D),
    error: Color(0xFFFFB4AB),
    info: Color(0xFF57C4E0),
    neutral: Color(0xFF78909C),
  );

  static ChartColors of(BuildContext context) =>
      Theme.of(context).extension<ChartColors>()!;

  @override
  ChartColors copyWith({
    Color? primary,
    Color? secondary,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? neutral,
  }) {
    return ChartColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  ChartColors lerp(ThemeExtension<ChartColors>? other, double t) {
    if (other is! ChartColors) {
      return this;
    }
    return ChartColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

/// Ambient surface colors used for soft background glows behind dashboards
/// and large content areas. All colors are low-alpha so they read as light.
@immutable
class AmbientColors extends ThemeExtension<AmbientColors> {
  const AmbientColors({
    required this.top,
    required this.bottom,
    required this.orbIndigo,
    required this.orbViolet,
    required this.orbTeal,
  });

  /// Top color of the ambient vertical gradient (usually the surface color).
  final Color top;

  /// Bottom color of the ambient vertical gradient.
  final Color bottom;

  /// Soft indigo glow orb.
  final Color orbIndigo;

  /// Soft violet glow orb.
  final Color orbViolet;

  /// Soft teal glow orb.
  final Color orbTeal;

  static const AmbientColors light = AmbientColors(
    top: Color(0xFFF6F7FC),
    bottom: Color(0xFFEFF1FA),
    orbIndigo: Color(0x14737BFF),
    orbViolet: Color(0x0F9E7CFF),
    orbTeal: Color(0x0D33C4E5),
  );

  static const AmbientColors dark = AmbientColors(
    top: Color(0xFF0D1526),
    bottom: Color(0xFF090F1D),
    orbIndigo: Color(0x1F6C7BFF),
    orbViolet: Color(0x17785DFF),
    orbTeal: Color(0x1227B2D9),
  );

  static AmbientColors of(BuildContext context) =>
      Theme.of(context).extension<AmbientColors>()!;

  @override
  AmbientColors copyWith({
    Color? top,
    Color? bottom,
    Color? orbIndigo,
    Color? orbViolet,
    Color? orbTeal,
  }) {
    return AmbientColors(
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
      orbIndigo: orbIndigo ?? this.orbIndigo,
      orbViolet: orbViolet ?? this.orbViolet,
      orbTeal: orbTeal ?? this.orbTeal,
    );
  }

  @override
  AmbientColors lerp(ThemeExtension<AmbientColors>? other, double t) {
    if (other is! AmbientColors) {
      return this;
    }
    return AmbientColors(
      top: Color.lerp(top, other.top, t)!,
      bottom: Color.lerp(bottom, other.bottom, t)!,
      orbIndigo: Color.lerp(orbIndigo, other.orbIndigo, t)!,
      orbViolet: Color.lerp(orbViolet, other.orbViolet, t)!,
      orbTeal: Color.lerp(orbTeal, other.orbTeal, t)!,
    );
  }
}
