import '../../models/app_user.dart';
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
    final firestore = _checkInRepo.firestoreInstance;
    final checkInRef = _checkInRepo.docRefFor(todayKey);
    final userRef = _userRepo.docRef;

    await firestore.runTransaction((transaction) async {
      final checkInSnap = await transaction.get(checkInRef);
      if (checkInSnap.exists && checkInSnap.data()!['type'] == CheckInType.checkedIn.value) {
        return; // already checked in today — idempotent no-op, no double streak credit.
      }

      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) return;
      final user = AppUser.fromMap(userRef.id, userSnap.data()!);

      final newStreak = user.currentStreak + 1;
      final newLongest = newStreak > user.longestStreak ? newStreak : user.longestStreak;

      transaction.set(checkInRef, CheckIn(
        date: todayKey,
        type: CheckInType.checkedIn,
        timestamp: today,
        workoutLogId: null,
      ).toMap());

      transaction.update(userRef, {
        'currentStreak': newStreak,
        'longestStreak': newLongest,
      });
    });
  }
}
