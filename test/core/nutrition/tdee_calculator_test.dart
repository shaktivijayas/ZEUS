import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/nutrition/tdee_calculator.dart';
import 'package:zeus/models/tdee_profile.dart';

void main() {
  const base = TdeeProfile(
    weightKg: 70,
    heightCm: 175,
    age: 25,
    sex: Sex.male,
    activityLevel: ActivityLevel.sedentary,
    goal: CalorieGoalDirection.maintain,
  );

  test('male, 70kg/175cm/25y, sedentary, maintain -> 2009 kcal, 151/201/67g macros', () {
    final result = calculateTdeeGoal(base);

    expect(result.calorieGoal, 2009);
    expect(result.macroGoals.protein, 151);
    expect(result.macroGoals.carbs, 201);
    expect(result.macroGoals.fat, 67);
  });

  test('female offset: 60kg/165cm/30y, light, lose -> 1315 kcal, 99/132/44g macros', () {
    const profile = TdeeProfile(
      weightKg: 60,
      heightCm: 165,
      age: 30,
      sex: Sex.female,
      activityLevel: ActivityLevel.light,
      goal: CalorieGoalDirection.lose,
    );

    final result = calculateTdeeGoal(profile);

    expect(result.calorieGoal, 1315);
    expect(result.macroGoals.protein, 99);
    expect(result.macroGoals.carbs, 132);
    expect(result.macroGoals.fat, 44);
  });

  test('gain adds 300 kcal on top of TDEE: same base profile, moderate activity, gain -> 2894 kcal', () {
    final result = calculateTdeeGoal(TdeeProfile(
      weightKg: base.weightKg,
      heightCm: base.heightCm,
      age: base.age,
      sex: base.sex,
      activityLevel: ActivityLevel.moderate,
      goal: CalorieGoalDirection.gain,
    ));

    expect(result.calorieGoal, 2894);
  });

  test('each activity multiplier scales TDEE proportionally from the same BMR (male/70kg/175cm/25y, maintain)', () {
    final expected = {
      ActivityLevel.sedentary: 2009,
      ActivityLevel.light: 2301,
      ActivityLevel.moderate: 2594,
      ActivityLevel.active: 2887,
      ActivityLevel.veryActive: 3180,
    };

    for (final entry in expected.entries) {
      final result = calculateTdeeGoal(TdeeProfile(
        weightKg: base.weightKg,
        heightCm: base.heightCm,
        age: base.age,
        sex: base.sex,
        activityLevel: entry.key,
        goal: CalorieGoalDirection.maintain,
      ));
      expect(result.calorieGoal, entry.value, reason: '${entry.key} should give ${entry.value} kcal');
    }
  });

  test('each goal direction adjusts the same sedentary TDEE (2008.5) correctly', () {
    final lose = calculateTdeeGoal(TdeeProfile(
      weightKg: base.weightKg, heightCm: base.heightCm, age: base.age, sex: base.sex,
      activityLevel: ActivityLevel.sedentary, goal: CalorieGoalDirection.lose,
    ));
    final maintain = calculateTdeeGoal(base);
    final gain = calculateTdeeGoal(TdeeProfile(
      weightKg: base.weightKg, heightCm: base.heightCm, age: base.age, sex: base.sex,
      activityLevel: ActivityLevel.sedentary, goal: CalorieGoalDirection.gain,
    ));

    expect(lose.calorieGoal, 1509);
    expect(maintain.calorieGoal, 2009);
    expect(gain.calorieGoal, 2309);
  });

  test('macro split is internally consistent: protein*4 + carbs*4 + fat*9 is within 5 kcal of calorieGoal', () {
    final result = calculateTdeeGoal(base);
    final macroCalories =
        result.macroGoals.protein * 4 + result.macroGoals.carbs * 4 + result.macroGoals.fat * 9;

    expect((macroCalories - result.calorieGoal).abs(), lessThanOrEqualTo(5));
  });
}
