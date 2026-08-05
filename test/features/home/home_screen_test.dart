import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/checkin/checkin_service.dart';
import 'package:zeus/core/firestore/checkin_repository.dart';
import 'package:zeus/core/firestore/split_repository.dart';
import 'package:zeus/core/firestore/user_repository.dart';
import 'package:zeus/core/firestore/workout_log_repository.dart';
import 'package:zeus/features/home/home_screen.dart';
import 'package:zeus/models/exercise_log.dart';
import 'package:zeus/models/exercise_target.dart';
import 'package:zeus/models/split_day.dart';
import 'package:zeus/models/workout_log.dart';

Future<void> pumpHome(WidgetTester tester, {
  required UserRepository userRepo,
  required SplitRepository splitRepo,
  required CheckInRepository checkInRepo,
  required WorkoutLogRepository workoutLogRepo,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: HomeScreen(
      userRepo: userRepo,
      splitRepo: splitRepo,
      checkInRepo: checkInRepo,
      workoutLogRepo: workoutLogRepo,
      checkInService: CheckInService(checkInRepo, userRepo),
      today: DateTime.utc(2026, 8, 2), // a Sunday
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  late FakeFirebaseFirestore firestore;
  late UserRepository userRepo;
  late SplitRepository splitRepo;
  late CheckInRepository checkInRepo;
  late WorkoutLogRepository workoutLogRepo;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    userRepo = UserRepository(firestore, 'uid-1');
    splitRepo = SplitRepository(firestore, 'uid-1');
    checkInRepo = CheckInRepository(firestore, 'uid-1');
    workoutLogRepo = WorkoutLogRepository(firestore, 'uid-1');
    await userRepo.createInitialUser(name: 'Vani', email: 'vani@example.com');
    await splitRepo.saveSplitDay(const SplitDay(
      id: 'sunday',
      label: 'Rest / Cardio',
      order: 0,
      exercises: [ExerciseTarget(name: 'Treadmill', targetSets: 1, targetReps: 20, targetWeight: 0, order: 0)],
    ));
  });

  testWidgets('tapping Check In grants streak credit and reveals the checklist', (tester) async {
    await pumpHome(tester, userRepo: userRepo, splitRepo: splitRepo, checkInRepo: checkInRepo, workoutLogRepo: workoutLogRepo);

    expect(find.text('Treadmill'), findsNothing);

    await tester.tap(find.byKey(const Key('home_check_in_button')));
    await tester.pumpAndSettle();

    final user = await userRepo.getUser();
    expect(user!.currentStreak, 1);
    expect(find.text('Treadmill'), findsOneWidget);
  });

  testWidgets('checking off the first exercise creates a draft workout log', (tester) async {
    await pumpHome(tester, userRepo: userRepo, splitRepo: splitRepo, checkInRepo: checkInRepo, workoutLogRepo: workoutLogRepo);
    await tester.tap(find.byKey(const Key('home_check_in_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('exercise_checkbox_Treadmill')));
    await tester.pumpAndSettle();

    final log = await workoutLogRepo.getForDate('2026-08-02');
    expect(log, isNotNull);
    expect(log!.status, WorkoutLogStatus.draft);
  });

  testWidgets('tapping a checked exercise again unchecks it', (tester) async {
    await pumpHome(tester, userRepo: userRepo, splitRepo: splitRepo, checkInRepo: checkInRepo, workoutLogRepo: workoutLogRepo);
    await tester.tap(find.byKey(const Key('home_check_in_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('exercise_checkbox_Treadmill')));
    await tester.pumpAndSettle();
    var log = await workoutLogRepo.getForDate('2026-08-02');
    expect(log!.exercises.first.status, ExerciseLogStatus.done);

    await tester.tap(find.byKey(const Key('exercise_checkbox_Treadmill')));
    await tester.pumpAndSettle();
    log = await workoutLogRepo.getForDate('2026-08-02');
    expect(log!.exercises.first.status, ExerciseLogStatus.skipped);

    final checkbox = tester.widget<CheckboxListTile>(find.byKey(const Key('exercise_checkbox_Treadmill')));
    expect(checkbox.value, false);
  });

  testWidgets('Finish with no exercises touched creates no workout log doc', (tester) async {
    await pumpHome(tester, userRepo: userRepo, splitRepo: splitRepo, checkInRepo: checkInRepo, workoutLogRepo: workoutLogRepo);
    await tester.tap(find.byKey(const Key('home_check_in_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_finish_button')));
    await tester.pumpAndSettle();

    final log = await workoutLogRepo.getForDate('2026-08-02');
    expect(log, isNull);
  });

  testWidgets('Finish after touching an exercise completes the draft', (tester) async {
    await pumpHome(tester, userRepo: userRepo, splitRepo: splitRepo, checkInRepo: checkInRepo, workoutLogRepo: workoutLogRepo);
    await tester.tap(find.byKey(const Key('home_check_in_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exercise_checkbox_Treadmill')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_finish_button')));
    await tester.pumpAndSettle();

    final log = await workoutLogRepo.getForDate('2026-08-02');
    expect(log!.status, WorkoutLogStatus.completed);
  });
}
