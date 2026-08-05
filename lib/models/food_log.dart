import 'food_entry.dart';

enum MealType {
  breakfast('breakfast'),
  lunch('lunch'),
  dinner('dinner'),
  snacks('snacks');

  const MealType(this.value);

  final String value;

  static MealType fromValue(String value) {
    return MealType.values.firstWhere((m) => m.value == value);
  }
}

class FoodLog {
  const FoodLog({required this.date, required this.meals});

  final String date;
  final Map<MealType, List<FoodEntry>> meals;

  factory FoodLog.empty(String date) {
    return FoodLog(date: date, meals: {for (final m in MealType.values) m: const []});
  }

  factory FoodLog.fromMap(String date, Map<String, dynamic> map) {
    final rawMeals = map['meals'] as Map<String, dynamic>? ?? {};
    return FoodLog(
      date: date,
      meals: {
        for (final m in MealType.values)
          m: ((rawMeals[m.value] as List<dynamic>?) ?? [])
              .map((e) => FoodEntry.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList(),
      },
    );
  }

  Map<String, dynamic> toMap() => {
        'meals': {
          for (final entry in meals.entries) entry.key.value: entry.value.map((e) => e.toMap()).toList(),
        },
      };

  double get totalCalories => meals.values.expand((e) => e).fold(0, (sum, e) => sum + e.calories);
  double get totalProtein => meals.values.expand((e) => e).fold(0, (sum, e) => sum + e.protein);
  double get totalCarbs => meals.values.expand((e) => e).fold(0, (sum, e) => sum + e.carbs);
  double get totalFat => meals.values.expand((e) => e).fold(0, (sum, e) => sum + e.fat);

  FoodLog copyWith({Map<MealType, List<FoodEntry>>? meals}) {
    return FoodLog(date: date, meals: meals ?? this.meals);
  }

  FoodLog withEntryAdded(MealType mealType, FoodEntry entry) {
    final updated = Map<MealType, List<FoodEntry>>.from(meals);
    updated[mealType] = [...(updated[mealType] ?? const []), entry];
    return copyWith(meals: updated);
  }

  FoodLog withEntryRemoved(MealType mealType, int index) {
    final updated = Map<MealType, List<FoodEntry>>.from(meals);
    final list = <FoodEntry>[...(updated[mealType] ?? const [])]..removeAt(index);
    updated[mealType] = list;
    return copyWith(meals: updated);
  }
}
