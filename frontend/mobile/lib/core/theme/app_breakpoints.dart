import 'package:flutter/material.dart';

/// Material 3 / Flutter responsive screen size buckets.
enum AppScreenSize { compact, medium, expanded }

/// Centralized responsive breakpoints and layout helpers.
///
/// - compact  : < 600px   (phones)
/// - medium   : 600-1023px (tablets / small desktops)
/// - expanded : >= 1024px (desktops, web)
class AppBreakpoints {
  AppBreakpoints._();

  static const double phone = 600;
  static const double tablet = 1024;
  static const double desktop = 1280;

  /// Maximum content width for large screens so lines stay readable.
  static const double maxContentWidth = 1200;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => widthOf(context) < phone;
  static bool isTablet(BuildContext context) =>
      widthOf(context) >= phone && widthOf(context) < tablet;
  static bool isDesktop(BuildContext context) => widthOf(context) >= tablet;

  static AppScreenSize sizeOf(BuildContext context) {
    final width = widthOf(context);
    if (width >= tablet) {
      return AppScreenSize.expanded;
    }
    if (width >= phone) {
      return AppScreenSize.medium;
    }
    return AppScreenSize.compact;
  }

  /// Horizontal page padding for the current screen size.
  static EdgeInsets horizontalPadding(BuildContext context) {
    final width = widthOf(context);
    if (width >= tablet) {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
    if (width >= phone) {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  /// Constrains content to a comfortable reading width, centered.
  static Widget constrain({required Widget child}) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxContentWidth),
      child: child,
    ),
  );
}
