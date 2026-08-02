import '../../models/check_in.dart';
import '../firestore/checkin_repository.dart';
import '../firestore/user_repository.dart';

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class CheckInService {
  CheckInService(this._checkInRepo, this._userRepo);

  final CheckInRepository _checkInRepo;
  final UserRepository _userRepo;

  Future<void> checkInToday({required DateTime today}) async {
    final todayKey = _dateKey(today);
    final existing = await _checkInRepo.getCheckIn(todayKey);
    if (existing != null && existing.type == CheckInType.checkedIn) {
      return; // already checked in today — idempotent no-op, no double streak credit.
    }

    final user = await _userRepo.getUser();
    if (user == null) return;

    await _checkInRepo.writeCheckIn(CheckIn(
      date: todayKey,
      type: CheckInType.checkedIn,
      timestamp: today,
      workoutLogId: null,
    ));

    final newStreak = user.currentStreak + 1;
    await _userRepo.updateStreakAndFreezes(
      currentStreak: newStreak,
      longestStreak: newStreak > user.longestStreak ? newStreak : user.longestStreak,
      freezesRemaining: user.freezesRemaining,
      freezesResetDate: user.freezesResetDate,
    );
  }
}
