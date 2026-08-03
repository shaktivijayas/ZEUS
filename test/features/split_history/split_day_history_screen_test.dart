import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/firestore/workout_log_repository.dart';
import 'package:zeus/features/split_history/split_day_history_screen.dart';
import 'package:zeus/models/exercise_log.dart';
import 'package:zeus/models/workout_log.dart';

void main() {
  testWidgets('shows completed logs for the split day, most recent first', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = WorkoutLogRepository(firestore, 'uid-1');

    final olderId = await repo.createDraft(const WorkoutLog(id: '', date: '2026-07-20', splitDayId: 'monday', status: WorkoutLogStatus.draft, exercises: [], completedAt: null));
    await repo.completeLog(olderId, const [
      ExerciseLog(name: 'Bench Press', targetSets: 4, targetReps: 8, targetWeight: 60, actualSets: 4, actualReps: 8, actualWeight: 60, status: ExerciseLogStatus.done, notes: ''),
    ]);

    final newerId = await repo.createDraft(const WorkoutLog(id: '', date: '2026-08-02', splitDayId: 'monday', status: WorkoutLogStatus.draft, exercises: [], completedAt: null));
    await repo.completeLog(newerId, const [
      ExerciseLog(name: 'Bench Press', targetSets: 4, targetReps: 8, targetWeight: 65, actualSets: 4, actualReps: 8, actualWeight: 65, status: ExerciseLogStatus.done, notes: ''),
    ]);

    await tester.pumpWidget(MaterialApp(
      home: SplitDayHistoryScreen(workoutLogRepo: repo, splitDayId: 'monday', splitDayLabel: 'Chest & Shoulders'),
    ));
    await tester.pumpAndSettle();

    final tiles = find.byType(ListTile);
    expect(tiles, findsNWidgets(2));
    expect(find.text('2026-08-02'), findsOneWidget);
  });
}
