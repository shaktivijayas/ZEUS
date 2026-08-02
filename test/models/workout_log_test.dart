import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/models/exercise_log.dart';
import 'package:zeus/models/workout_log.dart';

void main() {
  test('WorkoutLog round-trips with nested exercise logs, draft has no completedAt', () {
    final log = WorkoutLog(
      id: 'log-1',
      date: '2026-08-02',
      splitDayId: 'monday',
      status: WorkoutLogStatus.draft,
      exercises: const [
        ExerciseLog(
          name: 'Bench Press',
          targetSets: 4,
          targetReps: 8,
          targetWeight: 60,
          actualSets: 4,
          actualReps: 8,
          actualWeight: 62.5,
          status: ExerciseLogStatus.done,
          notes: 'felt strong',
        ),
      ],
      completedAt: null,
    );

    final restored = WorkoutLog.fromMap(log.id, log.toMap());

    expect(restored.status, WorkoutLogStatus.draft);
    expect(restored.completedAt, isNull);
    expect(restored.exercises.single.status, ExerciseLogStatus.done);
    expect(restored.exercises.single.actualWeight, 62.5);
  });

  test('completed WorkoutLog carries a completedAt timestamp', () {
    final completedAt = DateTime.utc(2026, 8, 2, 19, 30);
    final log = WorkoutLog(
      id: 'log-1',
      date: '2026-08-02',
      splitDayId: 'monday',
      status: WorkoutLogStatus.completed,
      exercises: const [],
      completedAt: completedAt,
    );

    final restored = WorkoutLog.fromMap(log.id, log.toMap());
    expect(restored.completedAt, completedAt);
  });
}
