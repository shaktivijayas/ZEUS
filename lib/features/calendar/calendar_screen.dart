import 'dart:ui';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/firestore/checkin_repository.dart';
import '../../core/firestore/food_log_repository.dart';
import '../../core/firestore/user_repository.dart';
import '../../core/firestore/workout_log_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/apple_fitness_palette.dart';
import '../../core/widgets/apple_bottom_bar.dart';
import '../../models/app_user.dart';
import '../../models/check_in.dart';
import '../../models/food_log.dart';
import '../../models/workout_log.dart';

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

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

enum _CalendarMode { rings, sessions }

/// Sessions-mode filter categories. Limited to what ZEUS actually tracks —
/// no fabricated "Mindfulness"/"Walking" categories with no data behind
/// them, unlike Apple's own Fitness app.
enum _SessionFilter { all, workouts, restDays }

const _rowHeight = 64.0;

/// One calendar day's aggregated status, computed once per build from the
/// three live streams below rather than re-queried per cell.
class _DayStatus {
  const _DayStatus({
    required this.moveProgress,
    required this.hasWorkout,
    required this.checkedIn,
    required this.isRestDay,
  });

  final double moveProgress;
  final bool hasWorkout;
  final bool checkedIn;
  final bool isRestDay;

  bool get isEmpty =>
      moveProgress <= 0 && !hasWorkout && !checkedIn && !isRestDay;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.checkInRepo,
    required this.workoutLogRepo,
    required this.foodLogRepo,
    required this.userRepo,
    required this.initialMonth,
  });

  final CheckInRepository checkInRepo;
  final WorkoutLogRepository workoutLogRepo;
  final FoodLogRepository foodLogRepo;
  final UserRepository userRepo;
  final DateTime initialMonth;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  _CalendarMode _mode = _CalendarMode.rings;
  _SessionFilter _filter = _SessionFilter.all;
  final _scrollController = ScrollController();
  late final List<DateTime> _days;
  late String _headerLabel;

  @override
  void initState() {
    super.initState();
    final referenceDate = widget.initialMonth;

    // Six months of history through the current month — a continuous,
    // Apple-Fitness-style flowing grid rather than a bounded per-month view,
    // scoped to a fixed lookback instead of true unbounded infinite scroll.
    final firstOfRangeMonth = DateTime.utc(
      referenceDate.year,
      referenceDate.month - 5,
      1,
    );
    final lastOfCurrentMonth = DateTime.utc(
      referenceDate.year,
      referenceDate.month + 1,
      0,
    );
    // DateTime.weekday is Mon=1..Sun=7; %7 remaps Sun=0..Sat=6 to match the
    // S M T W T F S header below.
    final rangeStart = firstOfRangeMonth.subtract(
      Duration(days: firstOfRangeMonth.weekday % 7),
    );
    final rangeEnd = lastOfCurrentMonth.add(
      Duration(days: 6 - (lastOfCurrentMonth.weekday % 7)),
    );

    _days = [
      for (
        var d = rangeStart;
        !d.isAfter(rangeEnd);
        d = d.add(const Duration(days: 1))
      )
        d,
    ];

    _headerLabel = DateFormat('MMMM yyyy').format(referenceDate);
    _scrollController.addListener(_onScroll);
    // Scrolls to widget.initialMonth's position, not literally today's real
    // date — the red "today" ring highlight (in build(), below) is the only
    // place actual wall-clock "today" matters; the initial scroll position
    // follows whatever reference date the caller passed in.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToReferenceDate(referenceDate),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToReferenceDate(DateTime referenceDate) {
    final index = _days.indexWhere((d) => _isSameDate(d, referenceDate));
    if (index == -1 || !_scrollController.hasClients) return;
    final row = index ~/ 7;
    _scrollController.jumpTo(
      (((row - 1).clamp(0, 1 << 30)) * _rowHeight).toDouble(),
    );
  }

  void _onScroll() {
    final row = (_scrollController.offset / _rowHeight).round().clamp(
      0,
      (_days.length / 7).ceil() - 1,
    );
    final dayIndex = (row * 7).clamp(0, _days.length - 1);
    final label = DateFormat('MMMM yyyy').format(_days[dayIndex]);
    if (label != _headerLabel) setState(() => _headerLabel = label);
  }

  Future<void> _markRestDay(String dateKey) async {
    final firestore = widget.checkInRepo.firestoreInstance;
    final ref = widget.checkInRepo.docRefFor(dateKey);

    await firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (snap.exists) return; // never overwrite an existing doc.

      transaction.set(
        ref,
        CheckIn(
          date: dateKey,
          type: CheckInType.restDay,
          timestamp: DateTime.now().toUtc(),
          workoutLogId: null,
        ).toMap(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final startKey = _dateKey(_days.first);
    final endKey = _dateKey(_days.last);
    final today = DateTime.now().toUtc();

    return Scaffold(
      backgroundColor: ApplePalette.background,
      body: SafeArea(
        child: StreamBuilder<AppUser?>(
          stream: widget.userRepo.watchUser(),
          builder: (context, userSnapshot) {
            final calorieGoal = userSnapshot.data?.calorieGoal;
            return StreamBuilder<List<CheckIn>>(
              stream: widget.checkInRepo.watchCheckInsForRange(
                startKey,
                endKey,
              ),
              builder: (context, checkInSnapshot) {
                final checkIns = {
                  for (final c in checkInSnapshot.data ?? const <CheckIn>[])
                    c.date: c,
                };
                return StreamBuilder<List<WorkoutLog>>(
                  stream: widget.workoutLogRepo.watchCompletedLogsForRange(
                    startKey,
                    endKey,
                  ),
                  builder: (context, workoutSnapshot) {
                    final workoutDates = {
                      for (final w
                          in workoutSnapshot.data ?? const <WorkoutLog>[])
                        w.date,
                    };
                    return StreamBuilder<List<FoodLog>>(
                      stream: widget.foodLogRepo.watchLogsForRange(
                        startKey,
                        endKey,
                      ),
                      builder: (context, foodSnapshot) {
                        final foodByDate = {
                          for (final f
                              in foodSnapshot.data ?? const <FoodLog>[])
                            f.date: f,
                        };

                        _DayStatus statusFor(DateTime date) {
                          final key = _dateKey(date);
                          final checkIn = checkIns[key];
                          final calories = foodByDate[key]?.totalCalories ?? 0;
                          final move = (calorieGoal != null && calorieGoal > 0)
                              ? (calories / calorieGoal).clamp(0.0, 1.0)
                              : 0.0;
                          return _DayStatus(
                            moveProgress: move,
                            hasWorkout: workoutDates.contains(key),
                            checkedIn: checkIn?.type == CheckInType.checkedIn,
                            isRestDay: checkIn?.type == CheckInType.restDay,
                          );
                        }

                        return Column(
                          children: [
                            _TopBar(
                              headerLabel: _headerLabel,
                              mode: _mode,
                              // go(), not maybePop() — Calendar is a tab-bar
                              // destination now reached via `go`, which
                              // clears the stack, so there's nothing left to
                              // pop back to; Home is the universal "root" tab.
                              onCancel: () => context.go('/home'),
                              onModeChanged: (m) => setState(() => _mode = m),
                            ),
                            const _WeekdayHeader(),
                            Expanded(
                              child: GridView.builder(
                                key: const Key('calendar_grid'),
                                controller: _scrollController,
                                padding: EdgeInsets.zero,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,
                                      mainAxisExtent: _rowHeight,
                                    ),
                                itemCount: _days.length,
                                itemBuilder: (context, index) {
                                  final date = _days[index];
                                  return _DayCell(
                                    date: date,
                                    isToday: _isSameDate(date, today),
                                    status: statusFor(date),
                                    mode: _mode,
                                    filter: _filter,
                                    monthLabel: date.day == 1
                                        ? DateFormat('MMM').format(date)
                                        : null,
                                    onTap: () => _markRestDay(_dateKey(date)),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_mode == _CalendarMode.sessions)
            _FilterBar(
              filter: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
          AppleBottomBar(
            active: AppleBottomTab.calendar,
            // `go`, not `push` — every tab press must reset to that tab's
            // root screen regardless of how deep the stack already is, or
            // Summary (which has no tab of its own to push) ends up acting
            // like a plain back button instead of "go home".
            onSummary: () => context.go('/home'),
            onSplit: () => context.go('/split-editor'),
            onCalories: () => context.go('/calories'),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.headerLabel,
    required this.mode,
    required this.onCancel,
    required this.onModeChanged,
  });

  final String headerLabel;
  final _CalendarMode mode;
  final VoidCallback onCancel;
  final ValueChanged<_CalendarMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              key: const Key('calendar_cancel'),
              onTap: onCancel,
              child: Text(
                'Cancel',
                style: _appleFont(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ApplePalette.exerciseGreen,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              headerLabel,
              textAlign: TextAlign.center,
              style: _appleFont(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ApplePalette.primaryText,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<_CalendarMode>(
                key: const Key('calendar_mode_toggle'),
                color: ApplePalette.card,
                onSelected: onModeChanged,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _CalendarMode.rings,
                    child: Text(
                      'Rings',
                      style: _appleFont(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: ApplePalette.primaryText,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: _CalendarMode.sessions,
                    child: Text(
                      'Sessions',
                      style: _appleFont(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: ApplePalette.primaryText,
                      ),
                    ),
                  ),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mode == _CalendarMode.rings ? 'Rings' : 'Sessions',
                      style: _appleFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ApplePalette.exerciseGreen,
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      size: 14,
                      color: ApplePalette.exerciseGreen,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          for (final label in _labels)
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: _appleFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ApplePalette.dateGray,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.status,
    required this.mode,
    required this.filter,
    required this.monthLabel,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final _DayStatus status;
  final _CalendarMode mode;
  final _SessionFilter filter;
  final String? monthLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('calendar_day_${_dateKey(date)}'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // A fixed-height Column (not natural-sized) so the extra month-label
      // line on a day-1 cell can't push this cell past the GridView's
      // uniform mainAxisExtent — an explicit `height: 1.0` on every Text
      // style below is required too, since Inter's default line-box is
      // taller than its fontSize and blew the budget by a couple of
      // pixels even with this fixed-height Column alone.
      child: SizedBox(
        height: _rowHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (monthLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  monthLabel!,
                  style: _appleFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ApplePalette.primaryText,
                  ).copyWith(height: 1.0),
                ),
              ),
            isToday
                ? Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: ApplePalette.moveRed,
                    ),
                    child: Text(
                      '${date.day}',
                      style: _appleFont(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ).copyWith(height: 1.0),
                    ),
                  )
                : Text(
                    '${date.day}',
                    style: _appleFont(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: ApplePalette.primaryText,
                    ).copyWith(height: 1.0),
                  ),
            const SizedBox(height: 3),
            SizedBox(
              height: 20,
              child: mode == _CalendarMode.rings
                  ? _RingCluster(status: status)
                  : _SessionGlyphs(status: status, filter: filter),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingCluster extends StatelessWidget {
  const _RingCluster({required this.status});

  final _DayStatus status;

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          _ring(
            diameter: 22,
            color: ApplePalette.dateGray.withValues(alpha: 0.15),
            progress: 1,
          ),
          _ring(
            diameter: 16,
            color: ApplePalette.dateGray.withValues(alpha: 0.15),
            progress: 1,
          ),
          _ring(
            diameter: 10,
            color: ApplePalette.dateGray.withValues(alpha: 0.15),
            progress: 1,
          ),
        ],
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        _ring(
          diameter: 22,
          color: ApplePalette.moveRed,
          progress: status.moveProgress,
          track: true,
        ),
        _ring(
          diameter: 16,
          color: ApplePalette.exerciseGreen,
          progress: status.hasWorkout ? 1 : 0,
          track: true,
        ),
        _ring(
          diameter: 10,
          color: ApplePalette.standCyan,
          progress: status.checkedIn ? 1 : 0,
          track: true,
        ),
      ],
    );
  }

  Widget _ring({
    required double diameter,
    required Color color,
    required double progress,
    bool track = false,
  }) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (track)
            CircularProgressIndicator(
              value: 1,
              strokeWidth: 3,
              color: color.withValues(alpha: 0.2),
              backgroundColor: Colors.transparent,
            ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            color: color,
            backgroundColor: Colors.transparent,
            strokeCap: StrokeCap.round,
          ),
        ],
      ),
    );
  }
}

class _SessionGlyphs extends StatelessWidget {
  const _SessionGlyphs({required this.status, required this.filter});

  final _DayStatus status;
  final _SessionFilter filter;

  @override
  Widget build(BuildContext context) {
    final showWorkout = status.hasWorkout && filter != _SessionFilter.restDays;
    final showRest = status.isRestDay && filter != _SessionFilter.workouts;

    if (!showWorkout && !showRest) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showWorkout)
          const Icon(
            Icons.directions_run,
            size: 16,
            color: ApplePalette.exerciseGreen,
          ),
        if (showWorkout && showRest) const SizedBox(width: 3),
        if (showRest)
          const Icon(
            CupertinoIcons.moon_fill,
            size: 14,
            color: ApplePalette.standCyan,
          ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onChanged});

  final _SessionFilter filter;
  final ValueChanged<_SessionFilter> onChanged;

  static const _pills = [
    (_SessionFilter.all, 'All'),
    (_SessionFilter.workouts, 'Workouts'),
    (_SessionFilter.restDays, 'Rest days'),
  ];

  @override
  Widget build(BuildContext context) {
    // No SafeArea here — this now sits above the persistent AppleBottomBar
    // (not at the true screen edge), which already accounts for the bottom
    // safe-area inset itself.
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          color: ApplePalette.tabBarBackground.withValues(alpha: 0.75),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (value, label) in _pills)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs / 2,
                    vertical: AppSpacing.xs,
                  ),
                  child: GestureDetector(
                    key: Key('calendar_filter_${value.name}'),
                    onTap: () => onChanged(value),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: filter == value
                            ? ApplePalette.exerciseGreen
                            : ApplePalette.divider,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        label,
                        style: _appleFont(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: filter == value
                              ? Colors.black
                              : ApplePalette.primaryText,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
