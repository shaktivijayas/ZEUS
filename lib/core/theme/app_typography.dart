import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Roboto';

  // Numeric displays (calorie totals, macro grams, streak counts) use this so
  // digits align as they change instead of shifting width per-glyph.
  static const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w600, height: 1.15),
    displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w600, height: 1.15),
    displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w600, height: 1.15),
    headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 26, fontWeight: FontWeight.w600, height: 1.2),
    headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w600, height: 1.2),
    headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w600, height: 1.2),
    titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 19, fontWeight: FontWeight.w600, height: 1.3),
    titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 17, fontWeight: FontWeight.w600, height: 1.3),
    titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
    bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, height: 1.4),
    bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w400, height: 1.4),
    bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w400, height: 1.4),
    labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.28),
    labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.26),
    labelSmall: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.22),
  );
}
