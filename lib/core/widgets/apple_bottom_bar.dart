import 'dart:ui';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/apple_fitness_palette.dart';

enum AppleBottomTab { summary, calendar, split, calories }

/// Frosted bottom tab bar shared by every screen reachable from it, so it
/// stays visible across navigation instead of only existing on Home.
class AppleBottomBar extends StatelessWidget {
  const AppleBottomBar({
    super.key,
    required this.active,
    this.onSummary,
    this.onCalendar,
    this.onSplit,
    this.onCalories,
  });

  final AppleBottomTab active;
  final VoidCallback? onSummary;
  final VoidCallback? onCalendar;
  final VoidCallback? onSplit;
  final VoidCallback? onCalories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60 + MediaQuery.of(context).padding.bottom,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: ApplePalette.tabBarBackground.withValues(alpha: 0.75),
            padding: EdgeInsets.only(top: AppSpacing.sm, bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AppleBottomBarItem(
                  icon: CupertinoIcons.gauge,
                  label: 'Summary',
                  active: active == AppleBottomTab.summary,
                  onTap: onSummary,
                ),
                _AppleBottomBarItem(
                  icon: CupertinoIcons.calendar,
                  label: 'Calendar',
                  active: active == AppleBottomTab.calendar,
                  onTap: onCalendar,
                ),
                _AppleBottomBarItem(
                  icon: CupertinoIcons.square_split_2x2,
                  label: 'Split',
                  active: active == AppleBottomTab.split,
                  onTap: onSplit,
                ),
                _AppleBottomBarItem(
                  icon: CupertinoIcons.flame,
                  label: 'Calories',
                  active: active == AppleBottomTab.calories,
                  onTap: onCalories,
                  itemKey: const Key('home_calories_button'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppleBottomBarItem extends StatelessWidget {
  const _AppleBottomBarItem({required this.icon, required this.label, this.active = false, this.onTap, this.itemKey});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final Key? itemKey;

  @override
  Widget build(BuildContext context) {
    final color = active ? ApplePalette.exerciseGreen : ApplePalette.dateGray;
    return InkWell(
      key: itemKey,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
