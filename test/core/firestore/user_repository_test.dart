import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/firestore/user_repository.dart';
import 'package:zeus/models/macro_goals.dart';
import 'package:zeus/models/tdee_profile.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = UserRepository(firestore, 'uid-1');
  });

  test('createInitialUser writes defaults: streak 0, freezes 2, onboarded false', () async {
    await repo.createInitialUser(name: 'Vani', email: 'vani@example.com');

    final user = await repo.getUser();
    expect(user, isNotNull);
    expect(user!.currentStreak, 0);
    expect(user.longestStreak, 0);
    expect(user.freezesRemaining, 2);
    expect(user.onboarded, isFalse);
  });

  test('updateStreakAndFreezes updates only the given fields', () async {
    await repo.createInitialUser(name: 'Vani', email: 'vani@example.com');

    await repo.updateStreakAndFreezes(
      currentStreak: 3,
      longestStreak: 3,
      freezesRemaining: 1,
      freezesResetDate: DateTime.utc(2026, 9, 1),
    );

    final user = await repo.getUser();
    expect(user!.currentStreak, 3);
    expect(user.longestStreak, 3);
    expect(user.freezesRemaining, 1);
  });

  test('setOnboarded flips onboarded to true', () async {
    await repo.createInitialUser(name: 'Vani', email: 'vani@example.com');
    await repo.setOnboarded();

    final user = await repo.getUser();
    expect(user!.onboarded, isTrue);
  });

  test('getUser returns null when no doc exists', () async {
    final user = await repo.getUser();
    expect(user, isNull);
  });

  test('updateCalorieGoal writes calorieGoal, macroGoals, and tdeeProfile', () async {
    await repo.createInitialUser(name: 'Vani', email: 'vani@example.com');

    await repo.updateCalorieGoal(
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

    final user = await repo.getUser();
    expect(user!.calorieGoal, 2009);
    expect(user.macroGoals!.protein, 151);
    expect(user.tdeeProfile!.weightKg, 70);
    expect(user.tdeeProfile!.sex, Sex.male);
  });
}
