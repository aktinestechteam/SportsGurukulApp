import 'package:flutter/material.dart';

/// Centralized elevation/shadow levels.
///
/// Shadows use a neutral deep-navy tint at low alpha so they read well in
/// both light and dark mode without looking muddy. Soft, diffuse shadows are
/// preferred over hard offsets for a premium SaaS look.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> none = [];

  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x0A0B1220), blurRadius: 10, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x050B1220), blurRadius: 20, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> small = [
    BoxShadow(color: Color(0x100B1220), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x080B1220), blurRadius: 32, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(color: Color(0x150B1220), blurRadius: 28, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A0B1220), blurRadius: 48, offset: Offset(0, 16)),
  ];

  static const List<BoxShadow> large = [
    BoxShadow(color: Color(0x1F0B1220), blurRadius: 44, offset: Offset(0, 14)),
    BoxShadow(color: Color(0x0F0B1220), blurRadius: 64, offset: Offset(0, 24)),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x260B1220), blurRadius: 56, offset: Offset(0, 18)),
    BoxShadow(color: Color(0x140B1220), blurRadius: 80, offset: Offset(0, 32)),
  ];

  /// Shadow for cards that raises them slightly on hover.
  static const List<BoxShadow> hover = [
    BoxShadow(color: Color(0x170B1220), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0D0B1220), blurRadius: 48, offset: Offset(0, 20)),
  ];
}
