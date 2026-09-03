import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/firestore/food_log_repository.dart';
import '../../core/firestore/user_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/apple_fitness_palette.dart';
import '../../core/widgets/apple_bottom_bar.dart';
import '../../models/app_user.dart';
import '../../models/food_log.dart';

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "Today" when [d] is the current calendar day, otherwise a localized
/// "Weekday, Mon d" label — replaces the raw ISO date key in the header.
String _dateLabel(DateTime d) {
  final now = DateTime.now().toUtc();
  final isToday =
      d.year == now.year && d.month == now.month && d.day == now.day;
  return isToday ? 'Today' : DateFormat('EEEE, MMM d').format(d);
}

String _formatNumber(num n) => NumberFormat('#,###').format(n.round());

/// Apple's real SF Pro can't be licensed/bundled for Android, so Inter — the
/// closest freely-licensed geometric sans and the community's standard
/// SF Pro stand-in on non-Apple platforms — is used for this screen's
/// Apple-styled headings and labels instead of the app-wide Roboto type
/// scale (AppTypography).
TextStyle _appleFont({
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  double? letterSpacing,
}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );
}

const _mealLabels = {
  MealType.breakfast: 'Breakfast',
  MealType.lunch: 'Lunch',
  MealType.dinner: 'Dinner',
  MealType.snacks: 'Snacks',
};

class CalorieLogScreen extends StatefulWidget {
  CalorieLogScreen({
    super.key,
    required this.foodLogRepo,
    required this.userRepo,
    DateTime? initialDate,
  }) : initialDate = initialDate ?? DateTime.now().toUtc();

  final FoodLogRepository foodLogRepo;
  final UserRepository userRepo;
  final DateTime initialDate;

  @override
  State<CalorieLogScreen> createState() => _CalorieLogScreenState();
}

class _CalorieLogScreenState extends State<CalorieLogScreen> {
  late DateTime _date = widget.initialDate;

  void _shiftDay(int delta) {
    setState(() => _date = _date.add(Duration(days: delta)));
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _dateKey(_date);
    return Scaffold(
      backgroundColor: ApplePalette.background,
      appBar: AppBar(
        backgroundColor: ApplePalette.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _dateLabel(_date),
          style: _appleFont(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ApplePalette.primaryText,
            letterSpacing: -0.4,
          ),
        ),
        // Both day-navigation controls live in `actions` (not `leading`) so
        // `leading` is left free for GoRouter/Navigator's default back
        // button — this screen is pushed from Home via context.push.
        actions: [
          IconButton(
            key: const Key('calorie_log_prev_day'),
            icon: const Icon(
              CupertinoIcons.chevron_left,
              color: ApplePalette.exerciseGreen,
              size: 22,
            ),
            onPressed: () => _shiftDay(-1),
          ),
          IconButton(
            key: const Key('calorie_log_next_day'),
            icon: const Icon(
              CupertinoIcons.chevron_right,
              color: ApplePalette.exerciseGreen,
              size: 22,
            ),
            onPressed: () => _shiftDay(1),
          ),
        ],
      ),
      bottomNavigationBar: AppleBottomBar(
        active: AppleBottomTab.calories,
        // `go`, not `push` — see the identical comment in calendar_screen.dart.
        onSummary: () => context.go('/home'),
        onCalendar: () => context.go('/calendar'),
        onSplit: () => context.go('/split-editor'),
      ),
      body: StreamBuilder<AppUser?>(
        stream: widget.userRepo.watchUser(),
        builder: (context, userSnapshot) {
          final calorieGoal = userSnapshot.data?.calorieGoal;
          return StreamBuilder<FoodLog>(
            stream: widget.foodLogRepo.watchForDate(dateKey),
            builder: (context, logSnapshot) {
              final log = logSnapshot.data ?? FoodLog.empty(dateKey);

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Center(
                    child: calorieGoal == null
                        ? _DormantHero(consumed: log.totalCalories.round())
                        : _CalorieRing(
                            consumed: log.totalCalories.round(),
                            goal: calorieGoal,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (final mealType in MealType.values) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Container(
                        decoration: BoxDecoration(
                          color: ApplePalette.card,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md + 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _mealLabels[mealType]!,
                                    style: _appleFont(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: ApplePalette.primaryText,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${log.meals[mealType]!.fold<double>(0, (sum, e) => sum + e.calories).round()} kcal',
                                  style: _appleFont(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: ApplePalette.dateGray,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                _AddMealButton(
                                  key: Key('add_food_${mealType.value}'),
                                  onTap: () => context.push(
                                    '/calories/$dateKey/add/${mealType.value}',
                                  ),
                                ),
                              ],
                            ),
                            for (final entry in log.meals[mealType]!)
                              Padding(
                                key: Key(
                                  'food_entry_${mealType.value}_${entry.name}',
                                ),
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.name,
                                        style: _appleFont(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: ApplePalette.primaryText,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${entry.calories.round()} kcal',
                                      style: _appleFont(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: ApplePalette.dateGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// The circular, glowing Move-ring hero — the primary visual centerpiece
/// once a calorie goal exists, replacing the flat "0 / 2009 kcal" text.
class _CalorieRing extends StatelessWidget {
  const _CalorieRing({required this.consumed, required this.goal});

  final int consumed;
  final int goal;

  @override
  Widget build(BuildContext context) {
    const size = 220.0;
    final progress = goal <= 0 ? 0.0 : (consumed / goal).clamp(0.0, 1.0);

    return Container(
      key: const Key('calorie_ring'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ApplePalette.background,
        boxShadow: [
          BoxShadow(
            color: ApplePalette.moveRed.withValues(alpha: 0.35),
            blurRadius: 36,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 16,
              color: ApplePalette.ringTrack,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 16,
              color: ApplePalette.moveRed,
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$consumed',
                style: _appleFont(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: ApplePalette.primaryText,
                  letterSpacing: -1.2,
                ).copyWith(fontFeatures: AppTypography.tabularFigures),
              ),
              const SizedBox(height: 2),
              Text(
                'of ${_formatNumber(goal)} kcal goal',
                style: _appleFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: ApplePalette.dateGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown before a calorie goal exists — the oversized total without a ring
/// (there's nothing to show progress against yet) plus the CTA to set one.
class _DormantHero extends StatelessWidget {
  const _DormantHero({required this.consumed});

  final int consumed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$consumed',
          style: _appleFont(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: ApplePalette.primaryText,
            letterSpacing: -1.2,
          ).copyWith(fontFeatures: AppTypography.tabularFigures),
        ),
        const SizedBox(height: 2),
        Text(
          'kcal logged today',
          style: _appleFont(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: ApplePalette.dateGray,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          key: const Key('calorie_log_set_goal_button'),
          onTap: () => context.push('/profile/calorie-goal'),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: ApplePalette.exerciseGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Set your goal',
              style: _appleFont(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Thin-line circular add affordance — replaces the plain "+" IconButton
/// with an iOS-style filled-circle button (subtle gray fill, crisp white
/// plus).
class _AddMealButton extends StatelessWidget {
  const _AddMealButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: ApplePalette.divider,
        ),
        child: const Icon(
          CupertinoIcons.add,
          size: 16,
          color: ApplePalette.primaryText,
        ),
      ),
    );
  }
}
