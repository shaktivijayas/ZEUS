import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/models/app_user.dart';

void main() {
  test('AppUser round-trips through toMap/fromMap', () {
    final resetDate = DateTime.utc(2026, 9, 2);
    final user = AppUser(
      uid: 'uid-1',
      name: 'Vani',
      email: 'vani@example.com',
      createdAt: DateTime.utc(2026, 8, 2),
      currentStreak: 3,
      longestStreak: 5,
      freezesRemaining: 1,
      freezesResetDate: resetDate,
      onboarded: true,
    );

    final restored = AppUser.fromMap(user.uid, user.toMap());

    expect(restored.uid, 'uid-1');
    expect(restored.name, 'Vani');
    expect(restored.currentStreak, 3);
    expect(restored.freezesRemaining, 1);
    expect(restored.freezesResetDate, resetDate);
    expect(restored.onboarded, isTrue);
  });

  test('copyWith overrides only the given fields', () {
    final user = AppUser(
      uid: 'uid-1',
      name: 'Vani',
      email: 'vani@example.com',
      createdAt: DateTime.utc(2026, 8, 2),
      currentStreak: 3,
      longestStreak: 5,
      freezesRemaining: 1,
      freezesResetDate: DateTime.utc(2026, 9, 2),
      onboarded: true,
    );

    final updated = user.copyWith(currentStreak: 4, freezesRemaining: 0);

    expect(updated.currentStreak, 4);
    expect(updated.freezesRemaining, 0);
    expect(updated.name, 'Vani');
  });
}
