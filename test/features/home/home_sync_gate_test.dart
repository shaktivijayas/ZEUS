import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/checkin/checkin_service.dart';
import 'package:zeus/core/firestore/checkin_repository.dart';
import 'package:zeus/core/firestore/food_log_repository.dart';
import 'package:zeus/core/firestore/split_repository.dart';
import 'package:zeus/core/firestore/user_repository.dart';
import 'package:zeus/core/firestore/workout_log_repository.dart';
import 'package:zeus/core/sync/app_open_sync_service.dart';
import 'package:zeus/features/home/home_sync_gate.dart';

void main() {
  testWidgets('shows a loading indicator until sync completes, then shows Home', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final userRepo = UserRepository(firestore, 'uid-1');
    final splitRepo = SplitRepository(firestore, 'uid-1');
    final checkInRepo = CheckInRepository(firestore, 'uid-1');
    final workoutLogRepo = WorkoutLogRepository(firestore, 'uid-1');
    final foodLogRepo = FoodLogRepository(firestore, 'uid-1');
    await userRepo.createInitialUser(name: 'Vani', email: 'vani@example.com');

    await tester.pumpWidget(MaterialApp(
      home: HomeSyncGate(
        userRepo: userRepo,
        splitRepo: splitRepo,
        checkInRepo: checkInRepo,
        workoutLogRepo: workoutLogRepo,
        foodLogRepo: foodLogRepo,
        checkInService: CheckInService(checkInRepo, userRepo),
        syncService: AppOpenSyncService(checkInRepo, userRepo),
      ),
    ));

    expect(find.byKey(const Key('home_sync_loading_indicator')), findsOneWidget);
    expect(find.byKey(const Key('home_check_in_button')), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_sync_loading_indicator')), findsNothing);
    expect(find.byKey(const Key('home_check_in_button')), findsOneWidget);
  });
}
