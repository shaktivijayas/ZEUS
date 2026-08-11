import 'package:flutter/material.dart';
import '../../core/checkin/checkin_service.dart';
import '../../core/firestore/checkin_repository.dart';
import '../../core/firestore/food_log_repository.dart';
import '../../core/firestore/split_repository.dart';
import '../../core/firestore/user_repository.dart';
import '../../core/firestore/workout_log_repository.dart';
import '../../core/sync/app_open_sync_service.dart';
import 'home_screen.dart';

/// Runs AppOpenSyncService.sync() once and blocks Home behind it, per spec:
/// the freeze-reset-then-gap-walk sequence must complete before Home is
/// interactive, so a Check In tap can never race the sync's writes.
class HomeSyncGate extends StatefulWidget {
  const HomeSyncGate({
    super.key,
    required this.userRepo,
    required this.splitRepo,
    required this.checkInRepo,
    required this.workoutLogRepo,
    required this.foodLogRepo,
    required this.checkInService,
    required this.syncService,
  });

  final UserRepository userRepo;
  final SplitRepository splitRepo;
  final CheckInRepository checkInRepo;
  final WorkoutLogRepository workoutLogRepo;
  final FoodLogRepository foodLogRepo;
  final CheckInService checkInService;
  final AppOpenSyncService syncService;

  @override
  State<HomeSyncGate> createState() => _HomeSyncGateState();
}

class _HomeSyncGateState extends State<HomeSyncGate> {
  late final Future<void> _syncFuture = widget.syncService.sync();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _syncFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(key: Key('home_sync_loading_indicator'))));
        }
        // A sync failure (e.g. offline on first launch) is treated as
        // non-fatal — Home still mounts and works against cached/local
        // state, consistent with the app's offline-tolerant design.
        return HomeScreen(
          userRepo: widget.userRepo,
          splitRepo: widget.splitRepo,
          checkInRepo: widget.checkInRepo,
          workoutLogRepo: widget.workoutLogRepo,
          foodLogRepo: widget.foodLogRepo,
          checkInService: widget.checkInService,
        );
      },
    );
  }
}
