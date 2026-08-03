import 'package:flutter/material.dart';
import '../../core/checkin/checkin_service.dart';
import '../../core/firestore/checkin_repository.dart';
import '../../core/firestore/split_repository.dart';
import '../../core/firestore/user_repository.dart';
import '../../core/firestore/workout_log_repository.dart';
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
  const HomeScreen({
    super.key,
    required this.userRepo,
    required this.splitRepo,
    required this.checkInRepo,
    required this.workoutLogRepo,
    required this.checkInService,
    DateTime? today,
  }) : today = today ?? DateTime.now;

  final UserRepository userRepo;
  final SplitRepository splitRepo;
  final CheckInRepository checkInRepo;
  final WorkoutLogRepository workoutLogRepo;
  final CheckInService checkInService;
  final dynamic today; // DateTime, kept dynamic only to allow the `??` default above

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DateTime _today = widget.today is DateTime ? widget.today as DateTime : DateTime.now().toUtc();
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

  Future<void> _toggleExercise(SplitDay day, int index) async {
    final exercise = day.exercises[index];
    if (_draft == null) {
      final id = await widget.workoutLogRepo.createDraft(WorkoutLog(
        id: '',
        date: _dateKey(_today),
        splitDayId: day.id,
        status: WorkoutLogStatus.draft,
        exercises: day.exercises
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
            .toList(),
        completedAt: null,
      ));
      final created = await widget.workoutLogRepo.getForDate(_dateKey(_today));
      setState(() => _draft = created!.copyWith(
            exercises: [
              for (var i = 0; i < created.exercises.length; i++)
                i == index
                    ? created.exercises[i].copyWith(status: ExerciseLogStatus.done, actualSets: exercise.targetSets, actualReps: exercise.targetReps, actualWeight: exercise.targetWeight)
                    : created.exercises[i],
            ],
          ));
      await widget.workoutLogRepo.updateLog(WorkoutLog(id: id, date: _draft!.date, splitDayId: _draft!.splitDayId, status: _draft!.status, exercises: _draft!.exercises, completedAt: null));
      return;
    }

    final updatedExercises = [
      for (var i = 0; i < _draft!.exercises.length; i++)
        i == index
            ? _draft!.exercises[i].copyWith(status: ExerciseLogStatus.done, actualSets: exercise.targetSets, actualReps: exercise.targetReps, actualWeight: exercise.targetWeight)
            : _draft!.exercises[i],
    ];
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
      appBar: AppBar(title: const Text('ZEUS')),
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Streak: ${user?.currentStreak ?? 0}', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 16),
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
