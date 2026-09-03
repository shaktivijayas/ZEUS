import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/firestore/workout_log_repository.dart';
import 'package:zeus/models/exercise_log.dart';
import 'package:zeus/models/workout_log.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late WorkoutLogRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = WorkoutLogRepository(firestore, 'uid-1');
  });

  test('createDraft then getForDate returns the draft', () async {
    final id = await repo.createDraft(const WorkoutLog(
      id: '',
      date: '2026-08-02',
      splitDayId: 'monday',
      status: WorkoutLogStatus.draft,
      exercises: [],
      completedAt: null,
    ));

    final fetched = await repo.getForDate('2026-08-02');
    expect(fetched, isNotNull);
    expect(fetched!.id, id);
    expect(fetched.status, WorkoutLogStatus.draft);
  });

  test('completeLog flips status to completed and sets completedAt', () async {
    final id = await repo.createDraft(const WorkoutLog(
      id: '',
      date: '2026-08-02',
      splitDayId: 'monday',
      status: WorkoutLogStatus.draft,
      exercises: [],
      completedAt: null,
    ));

    const finished = [
      ExerciseLog(
        name: 'Bench Press',
        targetSets: 4,
        targetReps: 8,
        targetWeight: 60,
        actualSets: 4,
        actualReps: 8,
        actualWeight: 60,
        status: ExerciseLogStatus.done,
        notes: '',
      ),
    ];

    await repo.completeLog(id, finished);

    final fetched = await repo.getForDate('2026-08-02');
    expect(fetched!.status, WorkoutLogStatus.completed);
    expect(fetched.completedAt, isNotNull);
    expect(fetched.exercises.single.status, ExerciseLogStatus.done);
  });

  test('getForDate returns null when no log exists for that date', () async {
    final fetched = await repo.getForDate('2026-08-02');
    expect(fetched, isNull);
  });

  test('watchCompletedLogsForRange includes only completed logs within the date range', () async {
    final inRangeCompletedId = await repo.createDraft(const WorkoutLog(
      id: '', date: '2026-08-10', splitDayId: 'monday', status: WorkoutLogStatus.draft, exercises: [], completedAt: null,
    ));
    await repo.completeLog(inRangeCompletedId, const []);

    // Draft (never completed) — must be excluded even though its date is in range.
    await repo.createDraft(const WorkoutLog(
      id: '', date: '2026-08-12', splitDayId: 'tuesday', status: WorkoutLogStatus.draft, exercises: [], completedAt: null,
    ));

    // Completed but outside the queried range — must be excluded.
    final outOfRangeId = await repo.createDraft(const WorkoutLog(
      id: '', date: '2026-09-05', splitDayId: 'monday', status: WorkoutLogStatus.draft, exercises: [], completedAt: null,
    ));
    await repo.completeLog(outOfRangeId, const []);

    final results = await repo.watchCompletedLogsForRange('2026-08-01', '2026-08-31').first;

    expect(results, hasLength(1));
    expect(results.single.date, '2026-08-10');
    expect(results.single.status, WorkoutLogStatus.completed);
  });
}
