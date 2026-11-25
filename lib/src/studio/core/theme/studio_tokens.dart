import 'package:flutter/material.dart';

/// Jarz brand tokens for the Studio. Colour values come from the brand
/// guidelines; the spacing and radius scales are shared by every Studio screen.
class StudioColors {
  StudioColors._();

  static const berryPink = Color(0xFFEF6B7A);
  static const softBlush = Color(0xFFF1CBE1);
  static const deepPlum = Color(0xFF434057);
  static const warmWhite = Color(0xFFFDFCFA);
  static const blushPale = Color(0xFFFDF5FA);

  /// Rare accent: gifting, premium moments only.
  static const jarzGold = Color(0xFFC4A265);

  /// Plum at reduced strength, for secondary text.
  static const plumMuted = Color(0xFF6E6B80);
  static const border = Color(0xFFE9DDE5);

  // Semantic (UI states only).
  static const success = Color(0xFF3F8F6B);
  static const warning = Color(0xFFB7791F);
  static const danger = Color(0xFFC0392B);
}

class StudioSpacing {
  StudioSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Page gutter on a phone.
  static const double gutter = 16;
}

class StudioRadii {
  StudioRadii._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double pill = 999;
}

/// Font families declared in pubspec.yaml.
class StudioFonts {
  StudioFonts._();

  static const display = 'DMSerifDisplay';
  static const body = 'Inter';
  static const arabic = 'Tajawal';
}
