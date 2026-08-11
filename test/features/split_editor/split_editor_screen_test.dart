import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/firestore/split_repository.dart';
import 'package:zeus/features/split_editor/split_editor_screen.dart';
import 'package:zeus/models/exercise_target.dart';
import 'package:zeus/models/split_day.dart';

void main() {
  testWidgets('shows all 7 weekdays, unconfigured days show as rest days', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final firestore = FakeFirebaseFirestore();
    final repo = SplitRepository(firestore, 'uid-1');

    await tester.pumpWidget(MaterialApp(home: SplitEditorScreen(splitRepo: repo)));
    await tester.pumpAndSettle();

    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Sunday'), findsOneWidget);
    expect(find.text('Rest day — tap to configure'), findsNWidgets(7));
  });

  testWidgets('a configured weekday shows its label and exercise count instead of rest day', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final firestore = FakeFirebaseFirestore();
    final repo = SplitRepository(firestore, 'uid-1');
    await repo.saveSplitDay(const SplitDay(
      id: 'monday',
      label: 'Chest & Shoulders',
      order: 0,
      exercises: [ExerciseTarget(name: 'Bench Press', targetSets: 4, targetReps: 8, targetWeight: 60, order: 0)],
    ));

    await tester.pumpWidget(MaterialApp(home: SplitEditorScreen(splitRepo: repo)));
    await tester.pumpAndSettle();

    expect(find.text('Chest & Shoulders · 1 exercises'), findsOneWidget);
    expect(find.text('Rest day — tap to configure'), findsNWidgets(6));
  });
}
