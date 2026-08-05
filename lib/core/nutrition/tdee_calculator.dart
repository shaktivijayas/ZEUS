import '../../models/macro_goals.dart';
import '../../models/tdee_profile.dart';

class TdeeResult {
  const TdeeResult({required this.calorieGoal, required this.macroGoals});

  final int calorieGoal;
  final MacroGoals macroGoals;
}

/// Pure function implementing the spec's TDEE calculation: Mifflin-St Jeor
/// BMR scaled by activity level, adjusted by goal direction, then split into
/// a fixed 30/40/30 protein/carbs/fat macro ratio (4/4/9 kcal per gram).
TdeeResult calculateTdeeGoal(TdeeProfile profile) {
  final bmr = 10 * profile.weightKg +
      6.25 * profile.heightCm -
      5 * profile.age +
      (profile.sex == Sex.male ? 5 : -161);

  final tdee = bmr * profile.activityLevel.multiplier;

  final adjusted = switch (profile.goal) {
    CalorieGoalDirection.lose => tdee - 500,
    CalorieGoalDirection.maintain => tdee,
    CalorieGoalDirection.gain => tdee + 300,
  };

  final calorieGoal = adjusted.round();

  final proteinGrams = (calorieGoal * 0.30 / 4).round();
  final carbsGrams = (calorieGoal * 0.40 / 4).round();
  final fatGrams = (calorieGoal * 0.30 / 9).round();

  return TdeeResult(
    calorieGoal: calorieGoal,
    macroGoals: MacroGoals(protein: proteinGrams, carbs: carbsGrams, fat: fatGrams),
  );
}
