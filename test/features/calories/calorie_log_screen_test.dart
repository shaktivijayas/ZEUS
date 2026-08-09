import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/firestore/food_log_repository.dart';
import 'package:zeus/core/firestore/user_repository.dart';
import 'package:zeus/features/calories/calorie_log_screen.dart';
import 'package:zeus/models/food_entry.dart';
import 'package:zeus/models/food_log.dart';
import 'package:zeus/models/macro_goals.dart';
import 'package:zeus/models/tdee_profile.dart';

Future<void> pumpCalorieLog(WidgetTester tester, {
  required FoodLogRepository foodLogRepo,
  required UserRepository userRepo,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: CalorieLogScreen(
      foodLogRepo: foodLogRepo,
      userRepo: userRepo,
      initialDate: DateTime.utc(2026, 8, 5),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  late FakeFirebaseFirestore firestore;
  late FoodLogRepository foodLogRepo;
  late UserRepository userRepo;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    foodLogRepo = FoodLogRepository(firestore, 'uid-1');
    userRepo = UserRepository(firestore, 'uid-1');
    await userRepo.createInitialUser(name: 'Vani', email: 'vani@example.com');
  });

  testWidgets('shows dormant state with no progress bar when no goal is set', (tester) async {
    await pumpCalorieLog(tester, foodLogRepo: foodLogRepo, userRepo: userRepo);

    expect(find.byKey(const Key('calorie_log_set_goal_button')), findsOneWidget);
    expect(find.textContaining('/'), findsNothing);
  });

  testWidgets('shows progress against the goal once one is set', (tester) async {
    await userRepo.updateCalorieGoal(
      calorieGoal: 2000,
      macroGoals: const MacroGoals(protein: 150, carbs: 200, fat: 67),
      tdeeProfile: const TdeeProfile(
        weightKg: 70, heightCm: 175, age: 25,
        sex: Sex.male, activityLevel: ActivityLevel.sedentary, goal: CalorieGoalDirection.maintain,
      ),
    );
    await foodLogRepo.saveLog(FoodLog.empty('2026-08-05').withEntryAdded(
      MealType.breakfast,
      FoodEntry(name: 'Toast', calories: 200, protein: 6, carbs: 30, fat: 4, quantity: null, unit: null, source: FoodEntrySource.manual, loggedAt: DateTime.utc(2026, 8, 5, 8)),
    ));

    await pumpCalorieLog(tester, foodLogRepo: foodLogRepo, userRepo: userRepo);

    expect(find.text('200 / 2000 kcal'), findsOneWidget);
  });

  testWidgets('shows logged entries under their meal section', (tester) async {
    await foodLogRepo.saveLog(FoodLog.empty('2026-08-05').withEntryAdded(
      MealType.lunch,
      FoodEntry(name: 'Dal Makhani', calories: 350, protein: 18, carbs: 30, fat: 20, quantity: null, unit: null, source: FoodEntrySource.manual, loggedAt: DateTime.utc(2026, 8, 5, 13)),
    ));

    await pumpCalorieLog(tester, foodLogRepo: foodLogRepo, userRepo: userRepo);

    expect(find.byKey(const Key('food_entry_lunch_Dal Makhani')), findsOneWidget);
  });

  testWidgets('tapping next/prev day changes the displayed date and reloads that day\'s log', (tester) async {
    await foodLogRepo.saveLog(FoodLog.empty('2026-08-06').withEntryAdded(
      MealType.dinner,
      FoodEntry(name: 'Rice', calories: 300, protein: 6, carbs: 65, fat: 1, quantity: null, unit: null, source: FoodEntrySource.manual, loggedAt: DateTime.utc(2026, 8, 6, 20)),
    ));

    await pumpCalorieLog(tester, foodLogRepo: foodLogRepo, userRepo: userRepo);
    expect(find.text('2026-08-05'), findsOneWidget);

    await tester.tap(find.byKey(const Key('calorie_log_next_day')));
    await tester.pumpAndSettle();

    expect(find.text('2026-08-06'), findsOneWidget);
    expect(find.byKey(const Key('food_entry_dinner_Rice')), findsOneWidget);
  });

  testWidgets('day-navigation controls live in AppBar.actions, leaving leading free for the back button', (tester) async {
    await pumpCalorieLog(tester, foodLogRepo: foodLogRepo, userRepo: userRepo);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.leading, isNull);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.byKey(const Key('calorie_log_prev_day'))),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.byKey(const Key('calorie_log_next_day'))),
      findsOneWidget,
    );
  });
}
