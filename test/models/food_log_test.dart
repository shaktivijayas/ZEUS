import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/models/food_entry.dart';
import 'package:zeus/models/food_log.dart';

void main() {
  test('FoodLog.empty has all four meal keys, each an empty list', () {
    final log = FoodLog.empty('2026-08-05');

    expect(log.date, '2026-08-05');
    expect(log.meals.keys.toSet(), MealType.values.toSet());
    for (final list in log.meals.values) {
      expect(list, isEmpty);
    }
  });

  test('FoodLog round-trips through toMap/fromMap with nested entries', () {
    final entry = FoodEntry(
      name: 'Dal Makhani',
      calories: 350,
      protein: 18,
      carbs: 30,
      fat: 20,
      quantity: null,
      unit: null,
      source: FoodEntrySource.manual,
      loggedAt: DateTime.utc(2026, 8, 5, 13, 30),
    );
    final log = FoodLog.empty('2026-08-05').withEntryAdded(MealType.lunch, entry);

    final restored = FoodLog.fromMap('2026-08-05', log.toMap());

    expect(restored.meals[MealType.lunch], hasLength(1));
    expect(restored.meals[MealType.lunch]!.first.name, 'Dal Makhani');
    expect(restored.meals[MealType.lunch]!.first.calories, 350);
    expect(restored.meals[MealType.lunch]!.first.quantity, isNull);
    expect(restored.meals[MealType.breakfast], isEmpty);
  });

  test('an openfoodfacts entry round-trips quantity and unit', () {
    final entry = FoodEntry(
      name: 'Oats',
      calories: 150,
      protein: 5,
      carbs: 27,
      fat: 3,
      quantity: 50,
      unit: 'g',
      source: FoodEntrySource.openFoodFacts,
      loggedAt: DateTime.utc(2026, 8, 5, 8, 0),
    );
    final log = FoodLog.empty('2026-08-05').withEntryAdded(MealType.breakfast, entry);

    final restored = FoodLog.fromMap('2026-08-05', log.toMap());

    expect(restored.meals[MealType.breakfast]!.first.quantity, 50);
    expect(restored.meals[MealType.breakfast]!.first.unit, 'g');
    expect(restored.meals[MealType.breakfast]!.first.source, FoodEntrySource.openFoodFacts);
  });

  test('withEntryAdded appends only to the targeted meal', () {
    final log = FoodLog.empty('2026-08-05')
        .withEntryAdded(MealType.breakfast, _entry('Toast', 200))
        .withEntryAdded(MealType.breakfast, _entry('Eggs', 150));

    expect(log.meals[MealType.breakfast], hasLength(2));
    expect(log.meals[MealType.lunch], isEmpty);
  });

  test('withEntryRemoved removes only the entry at the given index in that meal', () {
    final log = FoodLog.empty('2026-08-05')
        .withEntryAdded(MealType.breakfast, _entry('Toast', 200))
        .withEntryAdded(MealType.breakfast, _entry('Eggs', 150));

    final updated = log.withEntryRemoved(MealType.breakfast, 0);

    expect(updated.meals[MealType.breakfast], hasLength(1));
    expect(updated.meals[MealType.breakfast]!.first.name, 'Eggs');
  });

  test('totalCalories sums entries across all meals', () {
    final log = FoodLog.empty('2026-08-05')
        .withEntryAdded(MealType.breakfast, _entry('Toast', 200))
        .withEntryAdded(MealType.lunch, _entry('Dal Makhani', 350))
        .withEntryAdded(MealType.snacks, _entry('Banana', 90));

    expect(log.totalCalories, 640);
  });
}

FoodEntry _entry(String name, double calories) {
  return FoodEntry(
    name: name,
    calories: calories,
    protein: 0,
    carbs: 0,
    fat: 0,
    quantity: null,
    unit: null,
    source: FoodEntrySource.manual,
    loggedAt: DateTime.utc(2026, 8, 5),
  );
}
