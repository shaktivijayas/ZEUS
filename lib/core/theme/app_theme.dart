import 'package:flutter/material.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  // Light palette — see DESIGN.md "Colors" and "Material ColorScheme Mapping".
  static const Color _forestGreen = Color(0xFF2E7D32);
  static const Color _ink = Color(0xFF1A1D1B);
  static const Color _mutedInk = Color(0xFF55605A);
  static const Color _background = Color(0xFFF6F8F6);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _divider = Color(0xFFE3E7E3);
  static const Color _error = Color(0xFFB3261E);

  // Dark palette — same role mapping, deliberately re-toned for a dark
  // background rather than an alpha-inverted copy of the light values
  // (DESIGN.md "The Dark-Is-Not-Optional Rule"). Forest Green lightens to
  // Material green 300 to hold contrast on the near-black background.
  static const Color _forestGreenDark = Color(0xFF81C784);
  static const Color _onForestGreenDark = Color(0xFF0B3B0F);
  static const Color _inkDark = Color(0xFFE7ECE1);
  static const Color _mutedInkDark = Color(0xFFA9B2A0);
  static const Color _backgroundDark = Color(0xFF14170D);
  static const Color _surfaceDark = Color(0xFF1E2317);
  static const Color _dividerDark = Color(0xFF3A4132);
  static const Color _errorDark = Color(0xFFE2A19B);
  static const Color _onErrorDark = Color(0xFF4E1410);

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: _forestGreen,
    brightness: Brightness.light,
  ).copyWith(
    primary: _forestGreen,
    onPrimary: Colors.white,
    surface: _background,
    surfaceContainerLowest: _surface,
    onSurface: _ink,
    onSurfaceVariant: _mutedInk,
    outline: _divider,
    outlineVariant: _divider,
    error: _error,
    onError: Colors.white,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: _forestGreen,
    brightness: Brightness.dark,
  ).copyWith(
    primary: _forestGreenDark,
    onPrimary: _onForestGreenDark,
    surface: _backgroundDark,
    surfaceContainerLowest: _surfaceDark,
    onSurface: _inkDark,
    onSurfaceVariant: _mutedInkDark,
    outline: _dividerDark,
    outlineVariant: _dividerDark,
    error: _errorDark,
    onError: _onErrorDark,
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _lightScheme,
        scaffoldBackgroundColor: _lightScheme.surface,
        textTheme: AppTypography.textTheme.apply(
          bodyColor: _lightScheme.onSurface,
          displayColor: _lightScheme.onSurface,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: _darkScheme,
        scaffoldBackgroundColor: _darkScheme.surface,
        textTheme: AppTypography.textTheme.apply(
          bodyColor: _darkScheme.onSurface,
          displayColor: _darkScheme.onSurface,
        ),
      );
}
