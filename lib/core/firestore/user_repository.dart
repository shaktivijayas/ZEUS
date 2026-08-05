import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';

class UserRepository {
  UserRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;

  DocumentReference<Map<String, dynamic>> get _doc => _firestore.collection('users').doc(_uid);

  DocumentReference<Map<String, dynamic>> get docRef => _doc;

  Future<AppUser?> getUser() async {
    final snap = await _doc.get();
    if (!snap.exists) return null;
    return AppUser.fromMap(_uid, snap.data()!);
  }

  Stream<AppUser?> watchUser() {
    return _doc.snapshots().map((snap) => snap.exists ? AppUser.fromMap(_uid, snap.data()!) : null);
  }

  Future<void> createInitialUser({required String name, required String email}) async {
    final now = DateTime.now().toUtc();
    final user = AppUser(
      uid: _uid,
      name: name,
      email: email,
      createdAt: now,
      currentStreak: 0,
      longestStreak: 0,
      freezesRemaining: 2,
      freezesResetDate: DateTime.utc(now.year, now.month, now.day).add(const Duration(days: 30)),
      onboarded: false,
      calorieGoal: null,
      macroGoals: null,
      tdeeProfile: null,
    );
    await _doc.set(user.toMap());
  }

  Future<void> updateStreakAndFreezes({
    required int currentStreak,
    int? longestStreak,
    required int freezesRemaining,
    required DateTime freezesResetDate,
  }) async {
    final update = <String, dynamic>{
      'currentStreak': currentStreak,
      'freezesRemaining': freezesRemaining,
      'freezesResetDate': freezesResetDate.toIso8601String(),
    };
    if (longestStreak != null) {
      update['longestStreak'] = longestStreak;
    }
    await _doc.update(update);
  }

  Future<void> setOnboarded() async {
    await _doc.update({'onboarded': true});
  }
}
