import 'package:flutter/material.dart';

/// Centralized border-radius scale.
class AppRadii {
  AppRadii._();

  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xl = 20;
  static const double glass = 24;
  static const double pill = 999;

  static Radius radius(double value) => Radius.circular(value);

  static BorderRadius br(double value) => BorderRadius.circular(value);

  static BorderRadius get brSmall => br(small);
  static BorderRadius get brMedium => br(medium);
  static BorderRadius get brLarge => br(large);
  static BorderRadius get brXl => br(xl);
  static BorderRadius get brGlass => br(glass);
  static BorderRadius get brPill => br(pill);

  static RoundedRectangleBorder rect(double value) =>
      RoundedRectangleBorder(borderRadius: br(value));
}
