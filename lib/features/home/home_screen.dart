import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/checkin/checkin_service.dart';
import '../../core/firestore/checkin_repository.dart';
import '../../core/firestore/split_repository.dart';
import '../../core/firestore/user_repository.dart';
import '../../core/firestore/workout_log_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/app_user.dart';
import '../../models/check_in.dart';
import '../../models/exercise_log.dart';
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
    required this.checkInService,
    DateTime? today,
  }) : today = today ?? DateTime.now().toUtc();

  final UserRepository userRepo;
  final SplitRepository splitRepo;
  final CheckInRepository checkInRepo;
  final WorkoutLogRepository workoutLogRepo;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZEUS'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: () => context.push('/calendar')),
          IconButton(icon: const Icon(Icons.edit_calendar), onPressed: () => context.push('/split-editor')),
          IconButton(icon: const Icon(Icons.person), onPressed: () => context.push('/profile')),
          IconButton(key: const Key('home_calories_button'), icon: const Icon(Icons.restaurant), onPressed: () => context.push('/calories')),
        ],
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

              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Streak: ${user?.currentStreak ?? 0}', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.md),
                    if (!_checkedInToday)
                      ElevatedButton(
                        key: const Key('home_check_in_button'),
                        onPressed: _checkIn,
                        child: const Text('Check In'),
                      )
                    else if (todayDay.isEmpty)
                      const Text('No split day configured for today. Set one up in the Split Editor.')
                    else ...[
                      Expanded(
                        child: ListView(
                          children: [
                            for (var i = 0; i < todayDay.first.exercises.length; i++)
                              CheckboxListTile(
                                key: Key('exercise_checkbox_${todayDay.first.exercises[i].name}'),
                                title: Text(todayDay.first.exercises[i].name),
                                value: _draft != null && _draft!.exercises.length > i && _draft!.exercises[i].status == ExerciseLogStatus.done,
                                onChanged: (_) => _toggleExercise(todayDay.first, i),
                              ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        key: const Key('home_finish_button'),
                        onPressed: _finish,
                        child: const Text('Finish'),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
