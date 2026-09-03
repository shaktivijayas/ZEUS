import 'package:flutter/material.dart';

/// Colors for HomeScreen, matched against an Apple Fitness-style "Summary"
/// mockup spec (exact hex values supplied by the user). Deliberately
/// outside AppTheme's ColorScheme — see DarkMockupPalette's header comment
/// for why these mockup-matched screens pin their own fixed palette. Kept
/// separate from DarkMockupPalette because the spec's black/green are
/// numerically different from that palette's (#000000 vs #0D0D0D,
/// #A7FE00 vs #7ED321) and losing that precision would drift from spec.
class ApplePalette {
  ApplePalette._();

  static const background = Color(0xFF000000);
  static const card = Color(0xFF1C1C1E);
  static const primaryText = Colors.white;
  static const secondaryText = Color(0x99EBEBF5);
  static const dateGray = Color(0xFF8E8E93);
  static const pink = Color(0xFFFF2D55);
  static const green = Color(0xFFA7FE00);
  static const divider = Color(0xFF2C2C2E);
  static const ringTrack = Color(0xFF400010);
  static const tabBarBackground = Color(0xFF121212);
  // Apple Fitness's three ring colors, at their exact system hex values —
  // used where a screen needs to match the real Fitness app rather than
  // this file's earlier approximations (`green`, `pink` above).
  static const exerciseGreen = Color(0xFF30D158);
  static const moveRed = Color(0xFFFA114F);
  static const standCyan = Color(0xFF00D4FF);
  // iOS dark-mode separator gray at low opacity — matches a native
  // disclosure chevron rather than a flat solid gray.
  static const chevron = Color(0x663C3C43);
}
