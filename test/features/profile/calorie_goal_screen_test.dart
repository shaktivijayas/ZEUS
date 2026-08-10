import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/firestore/user_repository.dart';
import 'package:zeus/features/profile/calorie_goal_screen.dart';
import 'package:zeus/models/macro_goals.dart';
import 'package:zeus/models/tdee_profile.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserRepository userRepo;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    userRepo = UserRepository(firestore, 'uid-1');
    await userRepo.createInitialUser(name: 'Vani', email: 'vani@example.com');
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: CalorieGoalScreen(userRepo: userRepo)));
    await tester.pumpAndSettle();
  }

  testWidgets('filling the form and saving computes and writes the TDEE goal', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(const Key('tdee_weight_field')), '70');
    await tester.enterText(find.byKey(const Key('tdee_height_field')), '175');
    await tester.enterText(find.byKey(const Key('tdee_age_field')), '25');
    // Defaults are male/sedentary/maintain; no chip taps needed to hit the 2009 kcal fixture.
    await tester.tap(find.byKey(const Key('tdee_save_button')));
    await tester.pumpAndSettle();

    final user = await userRepo.getUser();
    expect(user!.calorieGoal, 2009);
    expect(user.macroGoals!.protein, 151);
    expect(user.tdeeProfile!.weightKg, 70);
  });

  testWidgets('selecting female and lose changes the computed goal', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(const Key('tdee_weight_field')), '60');
    await tester.enterText(find.byKey(const Key('tdee_height_field')), '165');
    await tester.enterText(find.byKey(const Key('tdee_age_field')), '30');
    await tester.tap(find.byKey(const Key('tdee_sex_female')));
    await tester.tap(find.byKey(const Key('tdee_activity_light')));
    await tester.tap(find.byKey(const Key('tdee_goal_lose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tdee_save_button')));
    await tester.pumpAndSettle();

    final user = await userRepo.getUser();
    expect(user!.calorieGoal, 1315);
  });

  testWidgets('pre-fills from an existing tdeeProfile', (tester) async {
    await userRepo.updateCalorieGoal(
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

    await pumpScreen(tester);

    expect(find.text('70.0'), findsOneWidget);
    expect(find.text('175.0'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
  });

  testWidgets('tapping save with empty fields shows a visible validation error and does not write', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('tdee_save_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tdee_validation_error_text')), findsOneWidget);
    final user = await userRepo.getUser();
    expect(user!.calorieGoal, isNull, reason: 'invalid form must not write a calorie goal');
  });

  testWidgets('sex chips resolve fill/text color from ColorScheme per selection state', (tester) async {
    await pumpScreen(tester);
    final scheme = Theme.of(tester.element(find.byType(CalorieGoalScreen))).colorScheme;

    final selected = tester.widget<ChoiceChip>(find.byKey(const Key('tdee_sex_male')));
    final unselected = tester.widget<ChoiceChip>(find.byKey(const Key('tdee_sex_female')));

    expect(selected.selected, isTrue);
    expect(selected.selectedColor, scheme.primary);
    expect(selected.labelStyle?.color, scheme.onPrimary);

    expect(unselected.selected, isFalse);
    expect(unselected.backgroundColor, scheme.surfaceContainerLowest);
    expect(unselected.labelStyle?.color, scheme.onSurfaceVariant);
    expect(unselected.side?.color, scheme.outline);
  });
}
