import 'package:flutter/material.dart';

/// Shared colors for the screens matched pixel-for-pixel against external
/// dark/neon fitness-app mockups (auth, onboarding, split editor/detail,
/// split history). Deliberately outside AppTheme's ColorScheme — these
/// screens pin a fixed palette regardless of light/dark system theme,
/// rather than drawing from app-wide design tokens (see DESIGN.md), so
/// they're excluded from the design-tokens lint test.
class DarkMockupPalette {
  DarkMockupPalette._();

  static const background = Color(0xFF0D0D0D);
  static const card = Color(0xFF1C1C1C);
  static const cardAlt = Color(0xFF161616);
  static const accent = Color(0xFF7ED321);
  static const mutedText = Color(0xFF9A9A9A);
  static const divider = Color(0xFF2A2A2A);
  static const facebookBlue = Color(0xFF1877F2);
}
