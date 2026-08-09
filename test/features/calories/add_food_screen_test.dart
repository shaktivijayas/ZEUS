import 'dart:convert';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zeus/core/firestore/food_log_repository.dart';
import 'package:zeus/core/nutrition/food_search_repository.dart';
import 'package:zeus/features/calories/add_food_screen.dart';
import 'package:zeus/models/food_entry.dart';
import 'package:zeus/models/food_log.dart';

String _recentDateKey() {
  final d = DateTime.now().toUtc().subtract(const Duration(days: 1));
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Future<void> pumpAddFood(WidgetTester tester, {
  required FoodLogRepository foodLogRepo,
  required FoodSearchRepository foodSearchRepo,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: AddFoodScreen(
      foodLogRepo: foodLogRepo,
      foodSearchRepo: foodSearchRepo,
      date: '2026-08-05',
      mealType: MealType.breakfast,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  late FakeFirebaseFirestore firestore;
  late FoodLogRepository foodLogRepo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    foodLogRepo = FoodLogRepository(firestore, 'uid-1');
  });

  testWidgets('manual entry saves a manual FoodEntry with quantity/unit null', (tester) async {
    final foodSearchRepo = FoodSearchRepository(MockClient((_) async => http.Response('{}', 200)));
    await pumpAddFood(tester, foodLogRepo: foodLogRepo, foodSearchRepo: foodSearchRepo);

    await tester.enterText(find.byKey(const Key('manual_name_field')), 'Dal Makhani');
    await tester.enterText(find.byKey(const Key('manual_calories_field')), '350');
    await tester.enterText(find.byKey(const Key('manual_protein_field')), '18');
    await tester.tap(find.byKey(const Key('manual_save_button')));
    await tester.pumpAndSettle();

    final log = await foodLogRepo.getForDate('2026-08-05');
    expect(log.meals[MealType.breakfast], hasLength(1));
    final entry = log.meals[MealType.breakfast]!.first;
    expect(entry.name, 'Dal Makhani');
    expect(entry.calories, 350);
    expect(entry.protein, 18);
    expect(entry.quantity, isNull);
    expect(entry.unit, isNull);
    expect(entry.source, FoodEntrySource.manual);
  });

  testWidgets('search mode: picking a result and entering quantity saves a scaled openfoodfacts entry', (tester) async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'products': [
            {
              'product_name': 'Rolled Oats',
              'nutriments': {
                'energy-kcal_100g': 380,
                'proteins_100g': 13,
                'carbohydrates_100g': 68,
                'fat_100g': 7,
              },
            },
          ],
        }),
        200,
      );
    });
    final foodSearchRepo = FoodSearchRepository(client);
    await pumpAddFood(tester, foodLogRepo: foodLogRepo, foodSearchRepo: foodSearchRepo);

    await tester.tap(find.byKey(const Key('add_food_mode_search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search_query_field')), 'oats');
    await tester.tap(find.byKey(const Key('search_run_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search_result_Rolled Oats')), findsOneWidget);
    await tester.tap(find.byKey(const Key('search_result_Rolled Oats')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('search_quantity_field')), '50');
    await tester.tap(find.byKey(const Key('search_save_button')));
    await tester.pumpAndSettle();

    final log = await foodLogRepo.getForDate('2026-08-05');
    final entry = log.meals[MealType.breakfast]!.first;
    expect(entry.name, 'Rolled Oats');
    expect(entry.calories, 190);
    expect(entry.quantity, 50);
    expect(entry.unit, 'g');
    expect(entry.source, FoodEntrySource.openFoodFacts);
  });

  testWidgets('search failure shows an inline error with a manual-entry fallback', (tester) async {
    final foodSearchRepo = FoodSearchRepository(MockClient((_) async => http.Response('error', 500)));
    await pumpAddFood(tester, foodLogRepo: foodLogRepo, foodSearchRepo: foodSearchRepo);

    await tester.tap(find.byKey(const Key('add_food_mode_search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search_query_field')), 'oats');
    await tester.tap(find.byKey(const Key('search_run_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search_error_text')), findsOneWidget);
    await tester.tap(find.byKey(const Key('search_switch_to_manual')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manual_name_field')), findsOneWidget);
  });

  testWidgets('tapping a recently-logged chip prefills the manual form and switches to manual mode', (tester) async {
    await foodLogRepo.saveLog(FoodLog.empty(_recentDateKey()).withEntryAdded(
      MealType.breakfast,
      FoodEntry(name: 'Toast', calories: 200, protein: 6, carbs: 30, fat: 4, quantity: null, unit: null, source: FoodEntrySource.manual, loggedAt: DateTime.utc(2026, 8, 1, 8)),
    ));
    final foodSearchRepo = FoodSearchRepository(MockClient((_) async => http.Response('{}', 200)));
    await pumpAddFood(tester, foodLogRepo: foodLogRepo, foodSearchRepo: foodSearchRepo);

    await tester.tap(find.byKey(const Key('add_food_mode_search')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recent_entry_Toast')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manual_name_field')), findsOneWidget);
    final nameField = tester.widget<TextField>(find.byKey(const Key('manual_name_field')));
    expect(nameField.controller!.text, 'Toast');
  });
}
