import '../../models/check_in.dart';
import '../firestore/checkin_repository.dart';
import '../firestore/user_repository.dart';
import '../streak/gap_walk.dart';

class AppOpenSyncService {
  AppOpenSyncService(this._checkInRepo, this._userRepo);

  final CheckInRepository _checkInRepo;
  final UserRepository _userRepo;

  Future<void> sync({DateTime? today}) async {
    final effectiveToday = today ?? _todayUtcMidnight();

    final user = await _userRepo.getUser();
    if (user == null) return;

    final lastActivityDate = await _checkInRepo.getLastActivityDate(effectiveToday);
    final existingCheckIns = lastActivityDate == null
        ? <String, CheckIn>{}
        : await _checkInRepo.getCheckInsInRange(lastActivityDate, effectiveToday);

    final result = runGapWalk(
      lastActivityDate: lastActivityDate,
      today: effectiveToday,
      currentStreak: user.currentStreak,
      freezesRemaining: user.freezesRemaining,
      freezesResetDate: user.freezesResetDate,
      existingCheckIns: existingCheckIns,
    );

    if (result.writes.isNotEmpty) {
      await _checkInRepo.writeCheckIns(result.writes);
    }

    final userStateChanged = result.newStreak != user.currentStreak ||
        result.newFreezesRemaining != user.freezesRemaining ||
        result.newFreezesResetDate != user.freezesResetDate;

    if (userStateChanged) {
      await _userRepo.updateStreakAndFreezes(
        currentStreak: result.newStreak,
        freezesRemaining: result.newFreezesRemaining,
        freezesResetDate: result.newFreezesResetDate,
      );
    }
  }

  DateTime _todayUtcMidnight() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }
}
