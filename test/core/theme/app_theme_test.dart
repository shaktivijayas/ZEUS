import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/theme/app_theme.dart';
import 'package:zeus/core/theme/app_typography.dart';

double _contrastRatio(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double lighter = la > lb ? la : lb;
  final double darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppTheme.light color scheme', () {
    final scheme = AppTheme.light.colorScheme;

    test('maps DESIGN.md roles to the spec\'s exact hex values', () {
      expect(scheme.brightness, Brightness.light);
      expect(scheme.primary, const Color(0xFF2E7D32)); // Deep Forest Green
      expect(scheme.onPrimary, const Color(0xFFFFFFFF));
      expect(scheme.surface, const Color(0xFFF6F8F6)); // Background
      expect(scheme.surfaceContainerLowest, const Color(0xFFFFFFFF)); // Surface
      expect(scheme.onSurface, const Color(0xFF1A1D1B)); // Ink
      expect(scheme.onSurfaceVariant, const Color(0xFF55605A)); // Muted Ink
      expect(scheme.outline, const Color(0xFFE3E7E3)); // Divider
      expect(scheme.outlineVariant, const Color(0xFFE3E7E3));
      expect(scheme.error, const Color(0xFFB3261E));
      expect(scheme.onError, const Color(0xFFFFFFFF));
    });
  });

  group('AppTheme.dark color scheme', () {
    final light = AppTheme.light.colorScheme;
    final dark = AppTheme.dark.colorScheme;

    test('inverts brightness and surfaces relative to light', () {
      expect(dark.brightness, Brightness.dark);
      expect(dark.surface.computeLuminance(), lessThan(light.surface.computeLuminance()));
      expect(dark.onSurface.computeLuminance(), greaterThan(dark.surface.computeLuminance()));
    });

    test('lightens the primary accent so it still contrasts a dark background', () {
      expect(dark.primary, isNot(equals(light.primary)));
      expect(_contrastRatio(dark.primary, dark.surface), greaterThanOrEqualTo(3.0));
    });

    test('body text and primary-on-accent text meet WCAG AA contrast', () {
      expect(_contrastRatio(dark.onSurface, dark.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.onPrimary, dark.primary), greaterThanOrEqualTo(4.5));
    });
  });

  group('AppTheme typography wiring', () {
    test('light and dark themes carry AppTypography sizes/weights through textTheme', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final display = theme.textTheme.displayMedium!;
        expect(display.fontFamily, AppTypography.fontFamily);
        expect(display.fontSize, AppTypography.textTheme.displayMedium!.fontSize);
        expect(display.fontWeight, AppTypography.textTheme.displayMedium!.fontWeight);
      }
    });
  });
}
