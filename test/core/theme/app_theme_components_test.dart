import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/theme/app_theme.dart';

void main() {
  for (final entry in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
    final themeName = entry.key;
    final theme = entry.value;
    final scheme = theme.colorScheme;

    group('AppTheme.$themeName components', () {
      test('elevated (primary) button: 8px radius, 12/24 padding, primary/onPrimary fill', () {
        final style = theme.elevatedButtonTheme.style!;
        final shape = style.shape?.resolve({}) as RoundedRectangleBorder?;
        expect(shape?.borderRadius, BorderRadius.circular(8));
        expect(style.padding?.resolve({}), const EdgeInsets.symmetric(horizontal: 24, vertical: 12));
        expect(style.backgroundColor?.resolve({}), scheme.primary);
        expect(style.foregroundColor?.resolve({}), scheme.onPrimary);
        expect(style.minimumSize?.resolve({})?.height, greaterThanOrEqualTo(48));
      });

      test('text (secondary) button: no fill, onSurface text', () {
        final style = theme.textButtonTheme.style!;
        expect(style.backgroundColor?.resolve({}), isNull);
        expect(style.foregroundColor?.resolve({}), scheme.onSurface);
        expect(style.minimumSize?.resolve({})?.height, greaterThanOrEqualTo(48));
      });

      test('cards: 12px radius, flat at rest, surfaceContainerLowest fill', () {
        expect(theme.cardTheme.elevation, 0);
        expect(theme.cardTheme.color, scheme.surfaceContainerLowest);
        final shape = theme.cardTheme.shape as RoundedRectangleBorder?;
        expect(shape?.borderRadius, BorderRadius.circular(12));
      });

      test('app bar: flat, Surface background, onSurface foreground, headline title', () {
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.backgroundColor, scheme.surfaceContainerLowest);
        expect(theme.appBarTheme.foregroundColor, scheme.onSurface);
        expect(theme.appBarTheme.titleTextStyle?.fontWeight, FontWeight.w600);
      });

      test('divider: Divider-role outline color', () {
        expect(theme.dividerTheme.color, scheme.outlineVariant);
      });

      test('inputs: Divider border at rest, primary border on focus, error border on error', () {
        final input = theme.inputDecorationTheme;
        final enabledBorder = input.enabledBorder as OutlineInputBorder?;
        final focusedBorder = input.focusedBorder as OutlineInputBorder?;
        final errorBorder = input.errorBorder as OutlineInputBorder?;

        expect(enabledBorder?.borderSide.color, scheme.outline);
        expect(focusedBorder?.borderSide.color, scheme.primary);
        expect(errorBorder?.borderSide.color, scheme.error);
        expect(input.filled, false);
      });

      test('chips: 8px shape, no checkmark decoration', () {
        final shape = theme.chipTheme.shape as RoundedRectangleBorder?;
        expect(shape?.borderRadius, BorderRadius.circular(8));
        expect(theme.chipTheme.showCheckmark, false);
      });
    });
  }
}
