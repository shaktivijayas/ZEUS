import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/checkin/checkin_service.dart';
import '../../core/firestore/checkin_repository.dart';
import '../../core/firestore/food_log_repository.dart';
import '../../core/firestore/split_repository.dart';
import '../../core/firestore/user_repository.dart';
import '../../core/firestore/workout_log_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/apple_fitness_palette.dart';
import '../../core/widgets/apple_bottom_bar.dart';
import '../../models/app_user.dart';
import '../../models/check_in.dart';
import '../../models/exercise_log.dart';
import '../../models/food_log.dart';
import '../../models/split_day.dart';
import '../../models/workout_log.dart';

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Monday=1 ... Sunday=7 (DateTime.weekday convention) mapped to the split
/// day ids used in the Split Editor. Phase 1 keeps this mapping simple: split
/// day ids created in Task 9/10 aren't required to match weekday names, so
/// Home falls back to "no split configured" whenever nothing matches.
const _weekdayIds = {
  1: 'monday',
  2: 'tuesday',
  3: 'wednesday',
  4: 'thursday',
  5: 'friday',
  6: 'saturday',
  7: 'sunday',
};

class HomeScreen extends StatefulWidget {
  HomeScreen({
    super.key,
    required this.userRepo,
    required this.splitRepo,
    required this.checkInRepo,
    required this.workoutLogRepo,
    required this.foodLogRepo,
    required this.checkInService,
    DateTime? today,
  }) : today = today ?? DateTime.now().toUtc();

  final UserRepository userRepo;
  final SplitRepository splitRepo;
  final CheckInRepository checkInRepo;
  final WorkoutLogRepository workoutLogRepo;
  final FoodLogRepository foodLogRepo;
  final CheckInService checkInService;
  final DateTime today;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DateTime _today = widget.today;
  bool _checkedInToday = false;
  WorkoutLog? _draft;

  @override
  void initState() {
    super.initState();
    _loadCheckInState();
  }

  Future<void> _loadCheckInState() async {
    final existing = await widget.checkInRepo.getCheckIn(_dateKey(_today));
    final draft = await widget.workoutLogRepo.getForDate(_dateKey(_today));
    if (!mounted) return;
    setState(() {
      _checkedInToday = existing != null && existing.type == CheckInType.checkedIn;
      _draft = draft;
    });
  }

  Future<void> _checkIn() async {
    await widget.checkInService.checkInToday(today: _today);
    await _loadCheckInState();
  }

  List<ExerciseLog> _blankExerciseLogs(SplitDay day) {
    return day.exercises
        .map((e) => ExerciseLog(
              name: e.name,
              targetSets: e.targetSets,
              targetReps: e.targetReps,
              targetWeight: e.targetWeight,
              actualSets: null,
              actualReps: null,
              actualWeight: null,
              status: ExerciseLogStatus.skipped,
              notes: '',
            ))
        .toList();
  }

  Future<void> _toggleExercise(SplitDay day, int index) async {
    final target = day.exercises[index];
    final baseExercises = _draft?.exercises ?? _blankExerciseLogs(day);
    final isDone = baseExercises[index].status == ExerciseLogStatus.done;
    final updatedExercises = [
      for (var i = 0; i < baseExercises.length; i++)
        i == index
            ? (isDone
                ? baseExercises[i].copyWith(status: ExerciseLogStatus.skipped)
                : baseExercises[i].copyWith(
                    status: ExerciseLogStatus.done,
                    actualSets: target.targetSets,
                    actualReps: target.targetReps,
                    actualWeight: target.targetWeight,
                  ))
            : baseExercises[i],
    ];

    if (_draft == null) {
      final id = await widget.workoutLogRepo.createDraft(WorkoutLog(
        id: '',
        date: _dateKey(_today),
        splitDayId: day.id,
        status: WorkoutLogStatus.draft,
        exercises: updatedExercises,
        completedAt: null,
      ));
      setState(() => _draft = WorkoutLog(
            id: id,
            date: _dateKey(_today),
            splitDayId: day.id,
            status: WorkoutLogStatus.draft,
            exercises: updatedExercises,
            completedAt: null,
          ));
      return;
    }

    final updated = _draft!.copyWith(exercises: updatedExercises);
    setState(() => _draft = updated);
    await widget.workoutLogRepo.updateLog(updated);
  }

  Future<void> _finish() async {
    if (_draft != null) {
      await widget.workoutLogRepo.completeLog(_draft!.id, _draft!.exercises);
    }
    // No draft: nothing to finalize, streak credit was already granted at check-in.
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final dateHeader = DateFormat('EEEE, MMM d').format(_today).toUpperCase();

    return Scaffold(
      backgroundColor: ApplePalette.background,
      bottomNavigationBar: AppleBottomBar(
        active: AppleBottomTab.summary,
        onCalendar: () => context.push('/calendar'),
        onSplit: () => context.push('/split-editor'),
        onCalories: () => context.push('/calories'),
      ),
      body: StreamBuilder<AppUser?>(
        stream: widget.userRepo.watchUser(),
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;
          return StreamBuilder<List<SplitDay>>(
            stream: widget.splitRepo.watchSplitDays(),
            builder: (context, daysSnapshot) {
              final days = daysSnapshot.data ?? const <SplitDay>[];
              final todayDay = days.where((d) => d.id == _weekdayIds[_today.weekday]).toList();
              final day = todayDay.isEmpty ? null : todayDay.first;
              final doneCount = _draft?.exercises.where((e) => e.status == ExerciseLogStatus.done).length ?? 0;

              return StreamBuilder<FoodLog>(
                stream: widget.foodLogRepo.watchForDate(_dateKey(_today)),
                builder: (context, foodSnapshot) {
                  final foodLog = foodSnapshot.data ?? FoodLog.empty(_dateKey(_today));

                  return SafeArea(
                    bottom: false,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md).copyWith(bottom: AppSpacing.xl),
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          dateHeader,
                          style: const TextStyle(
                            color: ApplePalette.dateGray,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.72,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(
                              child: Text(
                                'Summary',
                                style: TextStyle(color: ApplePalette.primaryText, fontSize: 34, fontWeight: FontWeight.bold),
                              ),
                            ),
                            GestureDetector(
                              key: const Key('home_profile_avatar'),
                              onTap: () => context.push('/profile'),
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundColor: ApplePalette.card,
                                child: Icon(Icons.person, color: ApplePalette.secondaryText),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Text(
                          'Activity',
                          style: TextStyle(color: ApplePalette.primaryText, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ActivityCard(
                          user: user,
                          caloriesConsumed: foodLog.totalCalories.round(),
                          exercisesDone: doneCount,
                          exercisesTotal: day?.exercises.length ?? 0,
                          hasSplitToday: day != null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            const Text(
                              'Workouts',
                              style: TextStyle(color: ApplePalette.primaryText, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.push('/split-editor'),
                              style: TextButton.styleFrom(foregroundColor: ApplePalette.green, minimumSize: Size.zero, padding: EdgeInsets.zero),
                              child: const Text('Show More', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (!_checkedInToday)
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              key: const Key('home_check_in_button'),
                              onPressed: _checkIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ApplePalette.green,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                elevation: 0,
                              ),
                              child: const Text('Check In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          )
                        else if (day == null)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(color: ApplePalette.card, borderRadius: BorderRadius.circular(14)),
                            child: const Text(
                              'No split day configured for today. Set one up in the Split Editor.',
                              style: TextStyle(color: ApplePalette.secondaryText),
                            ),
                          )
                        else ...[
                          for (var i = 0; i < day.exercises.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: CheckboxListTile(
                                key: Key('exercise_checkbox_${day.exercises[i].name}'),
                                value: _draft != null && _draft!.exercises.length > i && _draft!.exercises[i].status == ExerciseLogStatus.done,
                                onChanged: (_) => _toggleExercise(day, i),
                                controlAffinity: ListTileControlAffinity.trailing,
                                activeColor: ApplePalette.green,
                                checkColor: Colors.black,
                                tileColor: ApplePalette.card,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                secondary: const Icon(Icons.fitness_center, color: ApplePalette.pink),
                                title: Text(day.exercises[i].name, style: const TextStyle(color: ApplePalette.primaryText, fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${day.exercises[i].targetSets}x${day.exercises[i].targetReps} @ ${day.exercises[i].targetWeight}kg',
                                  style: const TextStyle(color: ApplePalette.secondaryText, fontSize: 13),
                                ),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              key: const Key('home_finish_button'),
                              onPressed: _finish,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ApplePalette.card,
                                foregroundColor: ApplePalette.primaryText,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                elevation: 0,
                              ),
                              child: const Text('Finish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.user,
    required this.caloriesConsumed,
    required this.exercisesDone,
    required this.exercisesTotal,
    required this.hasSplitToday,
  });

  final AppUser? user;
  final int caloriesConsumed;
  final int exercisesDone;
  final int exercisesTotal;
  final bool hasSplitToday;

  @override
  Widget build(BuildContext context) {
    final goal = user?.calorieGoal;
    final progress = goal == null || goal == 0 ? 0.0 : caloriesConsumed / goal;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: ApplePalette.card, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Calories', style: TextStyle(color: ApplePalette.primaryText, fontSize: 17)),
                const SizedBox(height: 2),
                goal == null
                    ? GestureDetector(
                        onTap: () => context.push('/profile/calorie-goal'),
                        child: const Text('Set your goal', style: TextStyle(color: ApplePalette.green, fontSize: 15, fontWeight: FontWeight.w600)),
                      )
                    : Text(
                        '$caloriesConsumed/${goal}CAL',
                        style: const TextStyle(color: ApplePalette.pink, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                const SizedBox(height: AppSpacing.md),
                const Text('Streak', style: TextStyle(color: ApplePalette.primaryText, fontSize: 17)),
                const SizedBox(height: 2),
                Text('${user?.currentStreak ?? 0} days', style: const TextStyle(color: ApplePalette.secondaryText, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.md),
                const Text('Today', style: TextStyle(color: ApplePalette.primaryText, fontSize: 17)),
                const SizedBox(height: 2),
                Text(
                  hasSplitToday ? '$exercisesDone/$exercisesTotal exercises' : 'Rest day',
                  style: const TextStyle(color: ApplePalette.secondaryText, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          _ActivityRing(progress: progress),
        ],
      ),
    );
  }
}

class _ActivityRing extends StatelessWidget {
  const _ActivityRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    const size = 110.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(value: 1, strokeWidth: 14, color: ApplePalette.ringTrack),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 14,
              color: ApplePalette.pink,
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }
}

