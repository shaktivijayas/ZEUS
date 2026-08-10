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

    final errorText = tester.widget<Text>(find.byKey(const Key('search_error_text')));
    final scheme = Theme.of(tester.element(find.byKey(const Key('search_error_text')))).colorScheme;
    expect(errorText.style?.color, scheme.error);
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

  testWidgets('manual save with an empty name shows feedback and does not save', (tester) async {
    final foodSearchRepo = FoodSearchRepository(MockClient((_) async => http.Response('{}', 200)));
    await pumpAddFood(tester, foodLogRepo: foodLogRepo, foodSearchRepo: foodSearchRepo);

    await tester.enterText(find.byKey(const Key('manual_calories_field')), '350');
    await tester.tap(find.byKey(const Key('manual_save_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('save_error_text')), findsOneWidget);
    final log = await foodLogRepo.getForDate('2026-08-05');
    expect(log.meals[MealType.breakfast], isEmpty);
  });

  testWidgets('manual save with non-numeric calories shows feedback and does not save', (tester) async {
    final foodSearchRepo = FoodSearchRepository(MockClient((_) async => http.Response('{}', 200)));
    await pumpAddFood(tester, foodLogRepo: foodLogRepo, foodSearchRepo: foodSearchRepo);

    await tester.enterText(find.byKey(const Key('manual_name_field')), 'Dal Makhani');
    await tester.enterText(find.byKey(const Key('manual_calories_field')), 'not-a-number');
    await tester.tap(find.byKey(const Key('manual_save_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('save_error_text')), findsOneWidget);
    final log = await foodLogRepo.getForDate('2026-08-05');
    expect(log.meals[MealType.breakfast], isEmpty);
  });

  testWidgets('search save with an unparseable quantity shows feedback and does not save', (tester) async {
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
    await tester.tap(find.byKey(const Key('search_result_Rolled Oats')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('search_quantity_field')), 'lots');
    await tester.tap(find.byKey(const Key('search_save_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('save_error_text')), findsOneWidget);
    final log = await foodLogRepo.getForDate('2026-08-05');
    expect(log.meals[MealType.breakfast], isEmpty);
  });

  testWidgets('a write failure on the initial read surfaces an error instead of throwing uncaught', (tester) async {
    final failingRepo = _FailingOnReadFoodLogRepository(firestore, 'uid-1');
    final foodSearchRepo = FoodSearchRepository(MockClient((_) async => http.Response('{}', 200)));
    await pumpAddFood(tester, foodLogRepo: failingRepo, foodSearchRepo: foodSearchRepo);

    await tester.enterText(find.byKey(const Key('manual_name_field')), 'Dal Makhani');
    await tester.enterText(find.byKey(const Key('manual_calories_field')), '350');
    await tester.tap(find.byKey(const Key('manual_save_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('save_error_text')), findsOneWidget);
    expect(tester.takeException(), isNull);
    // The button is re-enabled after the failure, not stuck disabled.
    final button = tester.widget<ElevatedButton>(find.byKey(const Key('manual_save_button')));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('a write failure that surfaces after the optimistic pop shows a SnackBar instead of throwing uncaught', (tester) async {
    final failingRepo = _FailingOnSaveFoodLogRepository(firestore, 'uid-1');
    final foodSearchRepo = FoodSearchRepository(MockClient((_) async => http.Response('{}', 200)));
    await pumpAddFood(tester, foodLogRepo: failingRepo, foodSearchRepo: foodSearchRepo);

    await tester.enterText(find.byKey(const Key('manual_name_field')), 'Dal Makhani');
    await tester.enterText(find.byKey(const Key('manual_calories_field')), '350');
    await tester.tap(find.byKey(const Key('manual_save_button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Failed to save entry'), findsOneWidget);
  });

  testWidgets('save button is disabled while a save is in flight, preventing a concurrent double-submit', (tester) async {
    final slowRepo = _SlowFoodLogRepository(firestore, 'uid-1');
    final foodSearchRepo = FoodSearchRepository(MockClient((_) async => http.Response('{}', 200)));
    await pumpAddFood(tester, foodLogRepo: slowRepo, foodSearchRepo: foodSearchRepo);

    await tester.enterText(find.byKey(const Key('manual_name_field')), 'Dal Makhani');
    await tester.enterText(find.byKey(const Key('manual_calories_field')), '350');
    await tester.tap(find.byKey(const Key('manual_save_button')));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byKey(const Key('manual_save_button')));
    expect(button.onPressed, isNull);

    await tester.pumpAndSettle();

    final log = await foodLogRepo.getForDate('2026-08-05');
    expect(log.meals[MealType.breakfast], hasLength(1));
  });
}

/// Fails on the initial `getForDate` read (before anything is popped),
/// simulating e.g. a Firestore `permission-denied` on read. Used to verify
/// `_saveEntry`'s error handling surfaces failures instead of throwing
/// uncaught, since `FakeFirebaseFirestore` doesn't naturally throw
/// permission errors.
class _FailingOnReadFoodLogRepository extends FoodLogRepository {
  _FailingOnReadFoodLogRepository(super.firestore, super.uid);

  @override
  Future<FoodLog> getForDate(String date) {
    throw Exception('permission-denied');
  }
}

/// Fails on `saveLog` (after the optimistic pop has already been
/// triggered), simulating a write that is rejected server-side.
class _FailingOnSaveFoodLogRepository extends FoodLogRepository {
  _FailingOnSaveFoodLogRepository(super.firestore, super.uid);

  @override
  Future<void> saveLog(FoodLog log) {
    throw Exception('permission-denied');
  }
}

/// Adds an artificial delay before the underlying save completes, widening
/// the window in which a double-tap could otherwise fire a second
/// concurrent save.
class _SlowFoodLogRepository extends FoodLogRepository {
  _SlowFoodLogRepository(super.firestore, super.uid);

  @override
  Future<void> saveLog(FoodLog log) async {
    await Future.delayed(const Duration(milliseconds: 50));
    await super.saveLog(log);
  }
}
