import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/checkin/checkin_service.dart';
import 'package:zeus/core/firestore/checkin_repository.dart';
import 'package:zeus/core/firestore/user_repository.dart';
import 'package:zeus/core/sync/app_open_sync_service.dart';
import 'package:zeus/models/check_in.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late CheckInRepository checkInRepo;
  late UserRepository userRepo;
  late AppOpenSyncService syncService;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    checkInRepo = CheckInRepository(firestore, 'uid-1');
    userRepo = UserRepository(firestore, 'uid-1');
    syncService = AppOpenSyncService(checkInRepo, userRepo);
    await userRepo.createInitialUser(name: 'Vani', email: 'vani@example.com');
  });

  test('first-ever open with no check-in history is a no-op', () async {
    await syncService.sync(today: DateTime.utc(2026, 8, 2));

    final user = await userRepo.getUser();
    expect(user!.currentStreak, 0);
    expect(user.freezesRemaining, 2);
  });

  test('a 3-day gap beyond the freeze budget backfills missed days and zeroes the streak', () async {
    await CheckInService(checkInRepo, userRepo).checkInToday(today: DateTime.utc(2026, 7, 29));
    await userRepo.updateStreakAndFreezes(
      currentStreak: 5,
      longestStreak: 5,
      freezesRemaining: 0,
      freezesResetDate: DateTime.utc(2026, 9, 1),
    );

    await syncService.sync(today: DateTime.utc(2026, 8, 2));

    final user = await userRepo.getUser();
    expect(user!.currentStreak, 0);

    final gapDoc = await checkInRepo.getCheckIn('2026-07-30');
    expect(gapDoc!.type, CheckInType.missed);
  });

  test('a due freeze reset applies before the gap-walk runs', () async {
    await CheckInService(checkInRepo, userRepo).checkInToday(today: DateTime.utc(2026, 7, 31));
    await userRepo.updateStreakAndFreezes(
      currentStreak: 5,
      longestStreak: 5,
      freezesRemaining: 0,
      freezesResetDate: DateTime.utc(2026, 8, 1),
    );

    await syncService.sync(today: DateTime.utc(2026, 8, 2));

    final user = await userRepo.getUser();
    // Gap day Aug 1 is bridged by the freshly-reset freeze budget (2, minus 1 used).
    expect(user!.currentStreak, 5);
    expect(user.freezesRemaining, 1);
    final gapDoc = await checkInRepo.getCheckIn('2026-08-01');
    expect(gapDoc!.type, CheckInType.freezeUsed);
  });
}
