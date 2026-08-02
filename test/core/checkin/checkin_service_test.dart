import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/checkin/checkin_service.dart';
import 'package:zeus/core/firestore/checkin_repository.dart';
import 'package:zeus/core/firestore/user_repository.dart';
import 'package:zeus/models/check_in.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late CheckInRepository checkInRepo;
  late UserRepository userRepo;
  late CheckInService service;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    checkInRepo = CheckInRepository(firestore, 'uid-1');
    userRepo = UserRepository(firestore, 'uid-1');
    service = CheckInService(checkInRepo, userRepo);
    await userRepo.createInitialUser(name: 'Vani', email: 'vani@example.com');
  });

  test('checking in today writes a checked_in doc and increments currentStreak', () async {
    await service.checkInToday(today: DateTime.utc(2026, 8, 2));

    final checkIn = await checkInRepo.getCheckIn('2026-08-02');
    expect(checkIn!.type, CheckInType.checkedIn);

    final user = await userRepo.getUser();
    expect(user!.currentStreak, 1);
    expect(user.longestStreak, 1);
  });

  test('double check-in the same day is idempotent: streak increments only once', () async {
    await service.checkInToday(today: DateTime.utc(2026, 8, 2));
    await service.checkInToday(today: DateTime.utc(2026, 8, 2));

    final user = await userRepo.getUser();
    expect(user!.currentStreak, 1);
  });

  test('longestStreak only rises, never falls, when currentStreak exceeds it', () async {
    await userRepo.updateStreakAndFreezes(
      currentStreak: 5,
      longestStreak: 5,
      freezesRemaining: 2,
      freezesResetDate: DateTime.utc(2026, 9, 1),
    );

    await service.checkInToday(today: DateTime.utc(2026, 8, 2));

    final user = await userRepo.getUser();
    expect(user!.currentStreak, 6);
    expect(user.longestStreak, 6);
  });
}
