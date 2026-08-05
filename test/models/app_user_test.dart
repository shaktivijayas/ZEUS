import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/models/app_user.dart';
import 'package:zeus/models/macro_goals.dart';
import 'package:zeus/models/tdee_profile.dart';

void main() {
  test('AppUser round-trips through toMap/fromMap with null calorie fields', () {
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
      calorieGoal: null,
      macroGoals: null,
      tdeeProfile: null,
    );

    final restored = AppUser.fromMap(user.uid, user.toMap());

    expect(restored.uid, 'uid-1');
    expect(restored.name, 'Vani');
    expect(restored.currentStreak, 3);
    expect(restored.freezesRemaining, 1);
    expect(restored.freezesResetDate, resetDate);
    expect(restored.onboarded, isTrue);
    expect(restored.calorieGoal, isNull);
    expect(restored.macroGoals, isNull);
    expect(restored.tdeeProfile, isNull);
  });

  test('AppUser round-trips a set calorie goal with nested macroGoals and tdeeProfile', () {
    final user = AppUser(
      uid: 'uid-1',
      name: 'Vani',
      email: 'vani@example.com',
      createdAt: DateTime.utc(2026, 8, 2),
      currentStreak: 0,
      longestStreak: 0,
      freezesRemaining: 2,
      freezesResetDate: DateTime.utc(2026, 9, 2),
      onboarded: true,
      calorieGoal: 2009,
      macroGoals: const MacroGoals(protein: 151, carbs: 201, fat: 67),
      tdeeProfile: const TdeeProfile(
        weightKg: 70,
        heightCm: 175,
        age: 25,
        sex: Sex.male,
        activityLevel: ActivityLevel.sedentary,
        goal: CalorieGoalDirection.maintain,
      ),
    );

    final restored = AppUser.fromMap(user.uid, user.toMap());

    expect(restored.calorieGoal, 2009);
    expect(restored.macroGoals!.protein, 151);
    expect(restored.macroGoals!.carbs, 201);
    expect(restored.macroGoals!.fat, 67);
    expect(restored.tdeeProfile!.weightKg, 70);
    expect(restored.tdeeProfile!.sex, Sex.male);
    expect(restored.tdeeProfile!.activityLevel, ActivityLevel.sedentary);
    expect(restored.tdeeProfile!.goal, CalorieGoalDirection.maintain);
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
      calorieGoal: null,
      macroGoals: null,
      tdeeProfile: null,
    );

    final updated = user.copyWith(currentStreak: 4, freezesRemaining: 0, calorieGoal: 2000);

    expect(updated.currentStreak, 4);
    expect(updated.freezesRemaining, 0);
    expect(updated.name, 'Vani');
    expect(updated.calorieGoal, 2000);
  });
}
