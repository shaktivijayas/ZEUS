import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/firestore/split_repository.dart';
import 'package:zeus/features/split_editor/split_day_detail_screen.dart';
import 'package:zeus/models/exercise_target.dart';
import 'package:zeus/models/split_day.dart';

void main() {
  testWidgets('saving a label creates the split day doc', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = SplitRepository(firestore, 'uid-1');

    await tester.pumpWidget(MaterialApp(
      home: SplitDayDetailScreen(splitRepo: repo, dayId: 'monday', weekdayLabel: 'Monday'),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('split_day_label_field')), 'Chest & Shoulders');
    await tester.tap(find.byKey(const Key('split_day_save_label_button')));
    await tester.pumpAndSettle();

    final days = await repo.watchSplitDays().first;
    expect(days.single.id, 'monday');
    expect(days.single.label, 'Chest & Shoulders');
  });

  testWidgets('adding an exercise appends it to the day', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = SplitRepository(firestore, 'uid-1');
    await repo.saveSplitDay(const SplitDay(id: 'monday', label: 'Chest', order: 0, exercises: []));

    await tester.pumpWidget(MaterialApp(
      home: SplitDayDetailScreen(splitRepo: repo, dayId: 'monday', weekdayLabel: 'Monday'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add_exercise_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('exercise_name_field')), 'Bench Press');
    await tester.tap(find.byKey(const Key('add_exercise_confirm_button')));
    await tester.pumpAndSettle();

    final days = await repo.watchSplitDays().first;
    expect(days.single.exercises, hasLength(1));
    expect(days.single.exercises.single.name, 'Bench Press');
  });

  testWidgets('deleting an exercise removes it from the day', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = SplitRepository(firestore, 'uid-1');
    await repo.saveSplitDay(const SplitDay(
      id: 'monday',
      label: 'Chest',
      order: 0,
      exercises: [ExerciseTarget(name: 'Bench Press', targetSets: 4, targetReps: 8, targetWeight: 60, order: 0)],
    ));

    await tester.pumpWidget(MaterialApp(
      home: SplitDayDetailScreen(splitRepo: repo, dayId: 'monday', weekdayLabel: 'Monday'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('delete_exercise_0')));
    await tester.pumpAndSettle();

    final days = await repo.watchSplitDays().first;
    expect(days.single.exercises, isEmpty);
  });
}
