# ZEUS Phase 2: Calorie Tracking — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a signed-in ZEUS user log food (manually or via Open Food Facts search) against a daily calorie/macro goal computed from a TDEE calculator, viewable by day with meal-grouped subtotals — independent of Phase 1's check-in/streak system.

**Architecture:** Extends the existing Flutter/Riverpod/Firebase app with one new Firestore subcollection (`foodLogs/{date}`, mirroring the existing `checkIns`/`workoutLogs` date-keyed-doc pattern), three new pure/data model files, two repositories, and three new screens wired into the existing GoRouter router exactly the way Calendar/Split Editor/Profile already are (icon button on Home's AppBar → `context.push`, repos constructed inline in the route builder).

**Tech Stack:** Flutter (Dart), Riverpod, GoRouter, Firebase Auth + Cloud Firestore, `http` (new dependency, for Open Food Facts), `fake_cloud_firestore` + `mocktail`/`http/testing.dart` for tests.

**Design spec:** `docs/superpowers/specs/2026-08-05-zeus-phase2-calorie-tracking-design.md` — read it for the full rationale; this plan implements it exactly.

## Global Constraints

- Android-only Flutter app, Riverpod for state management, Firebase Auth + Cloud Firestore backend, offline-first via Firestore's local cache with optimistic UI updates.
- Calorie tracking is **independent** of Phase 1's check-in/streak system — never touch `currentStreak`, `checkIns`, or the gap-walk algorithm.
- Follow existing repository conventions exactly: constructor-injected `FirebaseFirestore`/uid, no Riverpod DI for repositories (they're constructed directly in `GoRoute` builders, same as every existing route).
- Follow existing model conventions exactly: immutable classes, `required this.x` for every field (nullable or not), `fromMap`/`toMap`, enums as `(String value)`-backed with a `fromValue` static lookup.
- TDD throughout: failing test → minimal implementation → passing test → commit, one task at a time.
- No new external dependency beyond `http` (added in Task 6) — Open Food Facts requires no API key.

---

## File Structure

**New files:**
- `lib/models/food_entry.dart` — `FoodEntry` model, `FoodEntrySource` enum
- `lib/models/food_log.dart` — `FoodLog` model, `MealType` enum
- `lib/models/macro_goals.dart` — `MacroGoals` model
- `lib/models/tdee_profile.dart` — `TdeeProfile` model, `Sex`/`ActivityLevel`/`CalorieGoalDirection` enums
- `lib/core/nutrition/tdee_calculator.dart` — pure `calculateTdeeGoal()` function, `TdeeResult`
- `lib/core/nutrition/food_search_repository.dart` — `FoodSearchRepository`, `FoodSearchResult`, `FoodSearchException`
- `lib/core/firestore/food_log_repository.dart` — `FoodLogRepository`
- `lib/features/profile/calorie_goal_screen.dart` — `CalorieGoalScreen`
- `lib/features/calories/calorie_log_screen.dart` — `CalorieLogScreen`
- `lib/features/calories/add_food_screen.dart` — `AddFoodScreen`
- Matching `test/...` files for every file above (see each task).

**Modified files:**
- `pubspec.yaml` — add `http` dependency (Task 6)
- `lib/models/app_user.dart` — add `calorieGoal`/`macroGoals`/`tdeeProfile` fields (Task 2)
- `lib/core/firestore/user_repository.dart` — update `createInitialUser` for new fields (Task 2), add `updateCalorieGoal` (Task 5)
- `firestore.rules`, `firestore-tests/rules.test.js` — extend for `foodLogs` (Task 7)
- `lib/core/router/app_router.dart`, `lib/features/home/home_screen.dart`, `lib/features/profile/profile_screen.dart` — wire navigation (Task 11)
- `test/models/app_user_test.dart` (Task 2), `test/core/firestore/user_repository_test.dart` (Task 5), `test/features/home/home_screen_test.dart`, `test/features/profile/profile_screen_test.dart` (Task 11)

---

### Task 1: FoodEntry and FoodLog models

**Files:**
- Create: `lib/models/food_entry.dart`
- Create: `lib/models/food_log.dart`
- Test: `test/models/food_log_test.dart`

**Interfaces:**
- Produces: `FoodEntrySource` enum (`manual`, `openFoodFacts`); `FoodEntry` class with `fromMap`/`toMap`; `MealType` enum (`breakfast`, `lunch`, `dinner`, `snacks`); `FoodLog` class with `fromMap`/`toMap`/`copyWith`/`withEntryAdded`/`withEntryRemoved`/`totalCalories`/`totalProtein`/`totalCarbs`/`totalFat`/`FoodLog.empty(date)`.

- [ ] **Step 1: Write the failing test**

Create `test/models/food_log_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/food_log_test.dart`
Expected: FAIL to compile — `package:zeus/models/food_entry.dart` and `package:zeus/models/food_log.dart` don't exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/models/food_entry.dart`:

```dart
enum FoodEntrySource {
  manual('manual'),
  openFoodFacts('openfoodfacts');

  const FoodEntrySource(this.value);

  final String value;

  static FoodEntrySource fromValue(String value) {
    return FoodEntrySource.values.firstWhere((s) => s.value == value);
  }
}

/// A single logged food item. [calories]/[protein]/[carbs]/[fat] are always
/// the total for this entry, never a per-100g figure — for [FoodEntrySource.openFoodFacts]
/// entries they're computed by scaling a search result's per-100g data by
/// [quantity] grams at save time; for [FoodEntrySource.manual] entries the
/// user types the totals directly and [quantity]/[unit] stay null since
/// there's no per-100g baseline to scale from.
class FoodEntry {
  const FoodEntry({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.quantity,
    required this.unit,
    required this.source,
    required this.loggedAt,
  });

  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? quantity;
  final String? unit;
  final FoodEntrySource source;
  final DateTime loggedAt;

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      name: map['name'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      source: FoodEntrySource.fromValue(map['source'] as String),
      loggedAt: DateTime.parse(map['loggedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'quantity': quantity,
        'unit': unit,
        'source': source.value,
        'loggedAt': loggedAt.toIso8601String(),
      };
}
```

Create `lib/models/food_log.dart`:

```dart
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
    final list = [...(updated[mealType] ?? const [])]..removeAt(index);
    updated[mealType] = list;
    return copyWith(meals: updated);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/food_log_test.dart`
Expected: PASS (7 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/models/food_entry.dart lib/models/food_log.dart test/models/food_log_test.dart
git commit -m "Add FoodEntry and FoodLog models"
```

---

### Task 2: MacroGoals, TdeeProfile models; extend AppUser

**Files:**
- Create: `lib/models/macro_goals.dart`
- Create: `lib/models/tdee_profile.dart`
- Modify: `lib/models/app_user.dart`
- Modify: `lib/core/firestore/user_repository.dart` (`createInitialUser` only)
- Test: `test/models/app_user_test.dart`

**Interfaces:**
- Produces: `MacroGoals` class (`protein`/`carbs`/`fat` grams, `fromMap`/`toMap`); `Sex` enum (`male`, `female`); `ActivityLevel` enum (`sedentary` 1.2, `light` 1.375, `moderate` 1.55, `active` 1.725, `veryActive` 1.9 — value + `multiplier`); `CalorieGoalDirection` enum (`lose`, `maintain`, `gain`); `TdeeProfile` class (`weightKg`, `heightCm`, `age`, `sex`, `activityLevel`, `goal`, `fromMap`/`toMap`). `AppUser` gains `calorieGoal: int?`, `macroGoals: MacroGoals?`, `tdeeProfile: TdeeProfile?`, all `required` in the constructor (nullable, so callers pass `null` explicitly until the TDEE calculator has been used once).

- [ ] **Step 1: Write the failing test**

Replace `test/models/app_user_test.dart` in full:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/app_user_test.dart`
Expected: FAIL to compile — `AppUser` has no `calorieGoal`/`macroGoals`/`tdeeProfile` parameters, `macro_goals.dart`/`tdee_profile.dart` don't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/models/macro_goals.dart`:

```dart
class MacroGoals {
  const MacroGoals({required this.protein, required this.carbs, required this.fat});

  final int protein;
  final int carbs;
  final int fat;

  factory MacroGoals.fromMap(Map<String, dynamic> map) {
    return MacroGoals(
      protein: map['protein'] as int,
      carbs: map['carbs'] as int,
      fat: map['fat'] as int,
    );
  }

  Map<String, dynamic> toMap() => {'protein': protein, 'carbs': carbs, 'fat': fat};
}
```

Create `lib/models/tdee_profile.dart`:

```dart
enum Sex {
  male('male'),
  female('female');

  const Sex(this.value);

  final String value;

  static Sex fromValue(String value) => Sex.values.firstWhere((s) => s.value == value);
}

enum ActivityLevel {
  sedentary('sedentary', 1.2),
  light('light', 1.375),
  moderate('moderate', 1.55),
  active('active', 1.725),
  veryActive('very_active', 1.9);

  const ActivityLevel(this.value, this.multiplier);

  final String value;
  final double multiplier;

  static ActivityLevel fromValue(String value) => ActivityLevel.values.firstWhere((a) => a.value == value);
}

enum CalorieGoalDirection {
  lose('lose'),
  maintain('maintain'),
  gain('gain');

  const CalorieGoalDirection(this.value);

  final String value;

  static CalorieGoalDirection fromValue(String value) =>
      CalorieGoalDirection.values.firstWhere((g) => g.value == value);
}

class TdeeProfile {
  const TdeeProfile({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.sex,
    required this.activityLevel,
    required this.goal,
  });

  final double weightKg;
  final double heightCm;
  final int age;
  final Sex sex;
  final ActivityLevel activityLevel;
  final CalorieGoalDirection goal;

  factory TdeeProfile.fromMap(Map<String, dynamic> map) {
    return TdeeProfile(
      weightKg: (map['weightKg'] as num).toDouble(),
      heightCm: (map['heightCm'] as num).toDouble(),
      age: map['age'] as int,
      sex: Sex.fromValue(map['sex'] as String),
      activityLevel: ActivityLevel.fromValue(map['activityLevel'] as String),
      goal: CalorieGoalDirection.fromValue(map['goal'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'weightKg': weightKg,
        'heightCm': heightCm,
        'age': age,
        'sex': sex.value,
        'activityLevel': activityLevel.value,
        'goal': goal.value,
      };
}
```

Modify `lib/models/app_user.dart` — replace the whole file:

```dart
import 'macro_goals.dart';
import 'tdee_profile.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.currentStreak,
    required this.longestStreak,
    required this.freezesRemaining,
    required this.freezesResetDate,
    required this.onboarded,
    required this.calorieGoal,
    required this.macroGoals,
    required this.tdeeProfile,
  });

  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final int currentStreak;
  final int longestStreak;
  final int freezesRemaining;
  final DateTime freezesResetDate;
  final bool onboarded;
  final int? calorieGoal;
  final MacroGoals? macroGoals;
  final TdeeProfile? tdeeProfile;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] as String,
      email: map['email'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      currentStreak: map['currentStreak'] as int,
      longestStreak: map['longestStreak'] as int,
      freezesRemaining: map['freezesRemaining'] as int,
      freezesResetDate: DateTime.parse(map['freezesResetDate'] as String),
      onboarded: map['onboarded'] as bool,
      calorieGoal: map['calorieGoal'] as int?,
      macroGoals: map['macroGoals'] == null
          ? null
          : MacroGoals.fromMap(Map<String, dynamic>.from(map['macroGoals'] as Map)),
      tdeeProfile: map['tdeeProfile'] == null
          ? null
          : TdeeProfile.fromMap(Map<String, dynamic>.from(map['tdeeProfile'] as Map)),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'freezesRemaining': freezesRemaining,
        'freezesResetDate': freezesResetDate.toIso8601String(),
        'onboarded': onboarded,
        'calorieGoal': calorieGoal,
        'macroGoals': macroGoals?.toMap(),
        'tdeeProfile': tdeeProfile?.toMap(),
      };

  AppUser copyWith({
    String? name,
    String? email,
    int? currentStreak,
    int? longestStreak,
    int? freezesRemaining,
    DateTime? freezesResetDate,
    bool? onboarded,
    int? calorieGoal,
    MacroGoals? macroGoals,
    TdeeProfile? tdeeProfile,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      freezesRemaining: freezesRemaining ?? this.freezesRemaining,
      freezesResetDate: freezesResetDate ?? this.freezesResetDate,
      onboarded: onboarded ?? this.onboarded,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      macroGoals: macroGoals ?? this.macroGoals,
      tdeeProfile: tdeeProfile ?? this.tdeeProfile,
    );
  }
}
```

Modify `lib/core/firestore/user_repository.dart` — in `createInitialUser`, add the three new fields to the `AppUser(...)` construction:

```dart
  Future<void> createInitialUser({required String name, required String email}) async {
    final now = DateTime.now().toUtc();
    final user = AppUser(
      uid: _uid,
      name: name,
      email: email,
      createdAt: now,
      currentStreak: 0,
      longestStreak: 0,
      freezesRemaining: 2,
      freezesResetDate: DateTime.utc(now.year, now.month, now.day).add(const Duration(days: 30)),
      onboarded: false,
      calorieGoal: null,
      macroGoals: null,
      tdeeProfile: null,
    );
    await _doc.set(user.toMap());
  }
```

(Only the `AppUser(...)` call inside `createInitialUser` changes — every other method in the file is untouched.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/app_user_test.dart test/core/firestore/user_repository_test.dart`
Expected: PASS (3 + 4 tests — `user_repository_test.dart` needed no test changes, just confirming `createInitialUser`'s edit didn't break it)

- [ ] **Step 5: Commit**

```bash
git add lib/models/macro_goals.dart lib/models/tdee_profile.dart lib/models/app_user.dart lib/core/firestore/user_repository.dart test/models/app_user_test.dart
git commit -m "Add MacroGoals and TdeeProfile models, extend AppUser with calorie goal fields"
```

---

### Task 3: TDEE calculator (pure function)

**Files:**
- Create: `lib/core/nutrition/tdee_calculator.dart`
- Test: `test/core/nutrition/tdee_calculator_test.dart`

**Interfaces:**
- Consumes: `TdeeProfile`, `Sex`, `ActivityLevel`, `CalorieGoalDirection` (Task 2); `MacroGoals` (Task 2).
- Produces: `TdeeResult { calorieGoal: int, macroGoals: MacroGoals }`; `calculateTdeeGoal(TdeeProfile profile) -> TdeeResult`.

- [ ] **Step 1: Write the failing test**

Create `test/core/nutrition/tdee_calculator_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/nutrition/tdee_calculator_test.dart`
Expected: FAIL to compile — `package:zeus/core/nutrition/tdee_calculator.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/core/nutrition/tdee_calculator.dart`:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/nutrition/tdee_calculator_test.dart`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/nutrition/tdee_calculator.dart test/core/nutrition/tdee_calculator_test.dart
git commit -m "Add TDEE calculator pure function"
```

---

### Task 4: FoodLogRepository

**Files:**
- Create: `lib/core/firestore/food_log_repository.dart`
- Test: `test/core/firestore/food_log_repository_test.dart`

**Interfaces:**
- Consumes: `FoodLog`, `FoodEntry`, `MealType`, `FoodEntrySource` (Task 1).
- Produces: `FoodLogRepository(FirebaseFirestore, String uid)` with `getForDate(String date) -> Future<FoodLog>`, `watchForDate(String date) -> Stream<FoodLog>`, `saveLog(FoodLog log) -> Future<void>`, `getRecentEntries(DateTime today, {int lookbackDays = 7, int limit = 10}) -> Future<List<FoodEntry>>`.

- [ ] **Step 1: Write the failing test**

Create `test/core/firestore/food_log_repository_test.dart`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/firestore/food_log_repository.dart';
import 'package:zeus/models/food_entry.dart';
import 'package:zeus/models/food_log.dart';

FoodEntry _entry(String name, double calories, DateTime loggedAt) {
  return FoodEntry(
    name: name,
    calories: calories,
    protein: 0,
    carbs: 0,
    fat: 0,
    quantity: null,
    unit: null,
    source: FoodEntrySource.manual,
    loggedAt: loggedAt,
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late FoodLogRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FoodLogRepository(firestore, 'uid-1');
  });

  test('getForDate returns an empty FoodLog when no doc exists', () async {
    final log = await repo.getForDate('2026-08-05');
    expect(log.date, '2026-08-05');
    expect(log.totalCalories, 0);
  });

  test('saveLog then getForDate round-trips, doc ID is the date string', () async {
    final log = FoodLog.empty('2026-08-05').withEntryAdded(MealType.breakfast, _entry('Toast', 200, DateTime.utc(2026, 8, 5, 8)));
    await repo.saveLog(log);

    final restored = await repo.getForDate('2026-08-05');
    expect(restored.meals[MealType.breakfast], hasLength(1));
    expect(restored.meals[MealType.breakfast]!.first.name, 'Toast');

    final doc = await firestore.collection('users').doc('uid-1').collection('foodLogs').doc('2026-08-05').get();
    expect(doc.exists, isTrue);
  });

  test('watchForDate emits the current FoodLog for that date', () async {
    await repo.saveLog(FoodLog.empty('2026-08-05').withEntryAdded(MealType.lunch, _entry('Dal', 350, DateTime.utc(2026, 8, 5, 13))));

    final log = await repo.watchForDate('2026-08-05').first;

    expect(log.meals[MealType.lunch], hasLength(1));
    expect(log.meals[MealType.lunch]!.first.name, 'Dal');
  });

  test('getRecentEntries returns entries newest-first, deduplicated by name, within the lookback window', () async {
    await repo.saveLog(FoodLog.empty('2026-08-03').withEntryAdded(MealType.breakfast, _entry('Toast', 200, DateTime.utc(2026, 8, 3, 8))));
    await repo.saveLog(FoodLog.empty('2026-08-04').withEntryAdded(MealType.lunch, _entry('Dal', 350, DateTime.utc(2026, 8, 4, 13))));
    await repo.saveLog(FoodLog.empty('2026-08-05').withEntryAdded(MealType.dinner, _entry('Toast', 200, DateTime.utc(2026, 8, 5, 19))));
    // Outside a 7-day lookback from 2026-08-05 (2026-07-20 is 16 days earlier).
    await repo.saveLog(FoodLog.empty('2026-07-20').withEntryAdded(MealType.breakfast, _entry('Old Food', 100, DateTime.utc(2026, 7, 20, 8))));

    final recent = await repo.getRecentEntries(DateTime.utc(2026, 8, 5), lookbackDays: 7, limit: 10);

    expect(recent.map((e) => e.name).toList(), ['Toast', 'Dal']);
  });

  test('getRecentEntries respects the limit', () async {
    await repo.saveLog(FoodLog.empty('2026-08-05')
        .withEntryAdded(MealType.breakfast, _entry('A', 100, DateTime.utc(2026, 8, 5, 7)))
        .withEntryAdded(MealType.lunch, _entry('B', 100, DateTime.utc(2026, 8, 5, 12)))
        .withEntryAdded(MealType.dinner, _entry('C', 100, DateTime.utc(2026, 8, 5, 19))));

    final recent = await repo.getRecentEntries(DateTime.utc(2026, 8, 5), limit: 2);

    expect(recent, hasLength(2));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/firestore/food_log_repository_test.dart`
Expected: FAIL to compile — `package:zeus/core/firestore/food_log_repository.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/core/firestore/food_log_repository.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/food_entry.dart';
import '../../models/food_log.dart';

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class FoodLogRepository {
  FoodLogRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_uid).collection('foodLogs');

  Future<FoodLog> getForDate(String date) async {
    final snap = await _collection.doc(date).get();
    if (!snap.exists) return FoodLog.empty(date);
    return FoodLog.fromMap(date, snap.data()!);
  }

  Stream<FoodLog> watchForDate(String date) {
    return _collection.doc(date).snapshots().map((snap) {
      if (!snap.exists) return FoodLog.empty(date);
      return FoodLog.fromMap(date, snap.data()!);
    });
  }

  Future<void> saveLog(FoodLog log) async {
    await _collection.doc(log.date).set(log.toMap());
  }

  /// The user's own most recently logged entries across the last
  /// [lookbackDays] days (today inclusive), newest first, deduplicated by
  /// name, capped at [limit]. Powers the Add Food screen's "recently
  /// logged" quick-add — no separate food-catalog collection needed.
  Future<List<FoodEntry>> getRecentEntries(DateTime today, {int lookbackDays = 7, int limit = 10}) async {
    final startKey = _dateKey(today.subtract(Duration(days: lookbackDays - 1)));
    final endKey = _dateKey(today);
    final snap = await _collection
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
        .get();

    final logs = snap.docs.map((doc) => FoodLog.fromMap(doc.id, doc.data())).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final seen = <String>{};
    final recent = <FoodEntry>[];
    for (final log in logs) {
      final allEntries = [
        ...log.meals[MealType.breakfast]!,
        ...log.meals[MealType.lunch]!,
        ...log.meals[MealType.dinner]!,
        ...log.meals[MealType.snacks]!,
      ]..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      for (final entry in allEntries) {
        if (recent.length >= limit) return recent;
        if (seen.add(entry.name)) recent.add(entry);
      }
    }
    return recent;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/firestore/food_log_repository_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/firestore/food_log_repository.dart test/core/firestore/food_log_repository_test.dart
git commit -m "Add FoodLogRepository"
```

---

### Task 5: UserRepository.updateCalorieGoal

**Files:**
- Modify: `lib/core/firestore/user_repository.dart`
- Modify: `test/core/firestore/user_repository_test.dart`

**Interfaces:**
- Consumes: `MacroGoals`, `TdeeProfile` (Task 2).
- Produces: `UserRepository.updateCalorieGoal({required int calorieGoal, required MacroGoals macroGoals, required TdeeProfile tdeeProfile}) -> Future<void>`.

- [ ] **Step 1: Write the failing test**

Add to `test/core/firestore/user_repository_test.dart` (append inside `main()`, after the existing `setOnboarded` test; add the two new imports at the top):

```dart
import 'package:zeus/models/macro_goals.dart';
import 'package:zeus/models/tdee_profile.dart';
```

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/firestore/user_repository_test.dart`
Expected: FAIL to compile — `UserRepository` has no `updateCalorieGoal` method.

- [ ] **Step 3: Write the implementation**

In `lib/core/firestore/user_repository.dart`, add the import and method:

```dart
import '../../models/macro_goals.dart';
import '../../models/tdee_profile.dart';
```

```dart
  Future<void> updateCalorieGoal({
    required int calorieGoal,
    required MacroGoals macroGoals,
    required TdeeProfile tdeeProfile,
  }) async {
    await _doc.update({
      'calorieGoal': calorieGoal,
      'macroGoals': macroGoals.toMap(),
      'tdeeProfile': tdeeProfile.toMap(),
    });
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/firestore/user_repository_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/firestore/user_repository.dart test/core/firestore/user_repository_test.dart
git commit -m "Add UserRepository.updateCalorieGoal"
```

---

### Task 6: FoodSearchRepository (Open Food Facts)

**Files:**
- Modify: `pubspec.yaml` (add `http`)
- Create: `lib/core/nutrition/food_search_repository.dart`
- Test: `test/core/nutrition/food_search_repository_test.dart`

**Interfaces:**
- Consumes: `FoodEntry`, `FoodEntrySource` (Task 1).
- Produces: `FoodSearchResult { name, caloriesPer100g, proteinPer100g, carbsPer100g, fatPer100g, scaledEntry(double quantityGrams) -> FoodEntry }`; `FoodSearchException`; `FoodSearchRepository(http.Client)` with `search(String query) -> Future<List<FoodSearchResult>>`.

- [ ] **Step 1: Add the `http` dependency**

Run: `flutter pub add http`
Expected: `pubspec.yaml` gains an `http: ^<version>` line under `dependencies`, `pubspec.lock` updates.

- [ ] **Step 2: Write the failing test**

Create `test/core/nutrition/food_search_repository_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zeus/core/nutrition/food_search_repository.dart';
import 'package:zeus/models/food_entry.dart';

void main() {
  test('search parses well-formed products into FoodSearchResult', () async {
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
    final repo = FoodSearchRepository(client);

    final results = await repo.search('oats');

    expect(results, hasLength(1));
    expect(results.first.name, 'Rolled Oats');
    expect(results.first.caloriesPer100g, 380);
    expect(results.first.proteinPer100g, 13);
  });

  test('search filters out products missing a nutriment field', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'products': [
            {
              'product_name': 'Mystery Item',
              'nutriments': {'proteins_100g': 13, 'carbohydrates_100g': 68, 'fat_100g': 7},
            },
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
    final repo = FoodSearchRepository(client);

    final results = await repo.search('oats');

    expect(results, hasLength(1));
    expect(results.first.name, 'Rolled Oats');
  });

  test('search filters out products with a missing or blank name', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'products': [
            {
              'product_name': '',
              'nutriments': {
                'energy-kcal_100g': 100,
                'proteins_100g': 1,
                'carbohydrates_100g': 1,
                'fat_100g': 1,
              },
            },
          ],
        }),
        200,
      );
    });
    final repo = FoodSearchRepository(client);

    final results = await repo.search('x');

    expect(results, isEmpty);
  });

  test('search throws FoodSearchException on a non-200 response', () async {
    final client = MockClient((request) async => http.Response('Server error', 500));
    final repo = FoodSearchRepository(client);

    expect(() => repo.search('oats'), throwsA(isA<FoodSearchException>()));
  });

  test('FoodSearchResult.scaledEntry scales per-100g figures by the given quantity', () {
    const result = FoodSearchResult(
      name: 'Rolled Oats',
      caloriesPer100g: 380,
      proteinPer100g: 13,
      carbsPer100g: 68,
      fatPer100g: 7,
    );

    final entry = result.scaledEntry(50);

    expect(entry.name, 'Rolled Oats');
    expect(entry.calories, 190);
    expect(entry.protein, 6.5);
    expect(entry.carbs, 34);
    expect(entry.fat, 3.5);
    expect(entry.quantity, 50);
    expect(entry.unit, 'g');
    expect(entry.source, FoodEntrySource.openFoodFacts);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/core/nutrition/food_search_repository_test.dart`
Expected: FAIL to compile — `package:zeus/core/nutrition/food_search_repository.dart` doesn't exist.

- [ ] **Step 4: Write the implementation**

Create `lib/core/nutrition/food_search_repository.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/food_entry.dart';

class FoodSearchResult {
  const FoodSearchResult({
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  /// Scales this result's per-100g nutrition figures by [quantityGrams] into
  /// a saveable [FoodEntry] with totals, per the spec's "entries store
  /// totals, never per-100g figures" rule.
  FoodEntry scaledEntry(double quantityGrams) {
    return FoodEntry(
      name: name,
      calories: caloriesPer100g * quantityGrams / 100,
      protein: proteinPer100g * quantityGrams / 100,
      carbs: carbsPer100g * quantityGrams / 100,
      fat: fatPer100g * quantityGrams / 100,
      quantity: quantityGrams,
      unit: 'g',
      source: FoodEntrySource.openFoodFacts,
      loggedAt: DateTime.now().toUtc(),
    );
  }
}

class FoodSearchException implements Exception {
  FoodSearchException(this.message);

  final String message;

  @override
  String toString() => 'FoodSearchException: $message';
}

class FoodSearchRepository {
  FoodSearchRepository(this._client);

  final http.Client _client;

  static final _endpoint = Uri.parse('https://world.openfoodfacts.org/api/v2/search');

  Future<List<FoodSearchResult>> search(String query) async {
    final uri = _endpoint.replace(queryParameters: {
      'search_terms': query,
      'fields': 'product_name,nutriments',
      'page_size': '20',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw FoodSearchException('Open Food Facts returned ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final products = body['products'] as List<dynamic>? ?? [];

    return products
        .map((p) => _parseProduct(Map<String, dynamic>.from(p as Map)))
        .whereType<FoodSearchResult>()
        .toList();
  }

  FoodSearchResult? _parseProduct(Map<String, dynamic> product) {
    final name = product['product_name'] as String?;
    final nutriments = product['nutriments'] as Map<String, dynamic>?;
    if (name == null || name.trim().isEmpty || nutriments == null) return null;

    final calories = nutriments['energy-kcal_100g'];
    final protein = nutriments['proteins_100g'];
    final carbs = nutriments['carbohydrates_100g'];
    final fat = nutriments['fat_100g'];
    if (calories is! num || protein is! num || carbs is! num || fat is! num) return null;

    return FoodSearchResult(
      name: name,
      caloriesPer100g: calories.toDouble(),
      proteinPer100g: protein.toDouble(),
      carbsPer100g: carbs.toDouble(),
      fatPer100g: fat.toDouble(),
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/nutrition/food_search_repository_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/nutrition/food_search_repository.dart test/core/nutrition/food_search_repository_test.dart
git commit -m "Add FoodSearchRepository wrapping Open Food Facts search"
```

---

### Task 7: Firestore security rules for foodLogs

**Files:**
- Modify: `firestore.rules`
- Modify: `firestore-tests/rules.test.js`

**Interfaces:**
- Produces: `users/{uid}/foodLogs/{date}` covered by the same ownership rule as every other subcollection.

- [ ] **Step 1: Write the failing test**

In `firestore-tests/rules.test.js`, extend the existing "a user can write their own checkIns, splitDays, and workoutLogs subcollections" test to include `foodLogs`:

```js
  it('a user can write their own checkIns, splitDays, workoutLogs, and foodLogs subcollections', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const db = alice.firestore();

    await assertSucceeds(db.doc('users/alice/checkIns/2026-08-02').set({ type: 'checked_in' }));
    await assertSucceeds(db.doc('users/alice/splitDays/monday').set({ label: 'Chest' }));
    await assertSucceeds(db.doc('users/alice/workoutLogs/log1').set({ date: '2026-08-02' }));
    await assertSucceeds(db.doc('users/alice/foodLogs/2026-08-02').set({ meals: {} }));
  });
```

Add a new test after "a user cannot write another user's checkIns subcollection":

```js
  it('a user cannot write another user\'s foodLogs subcollection', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const db = alice.firestore();

    await assertFails(db.doc('users/bob/foodLogs/2026-08-02').set({ meals: {} }));
  });
```

- [ ] **Step 2: Run tests to verify the new assertions fail**

Run: `cd firestore-tests && npm test` (starts the Firebase emulator via `initializeTestEnvironment`, requires JDK — see Phase 1 Task 15's notes if the emulator isn't already runnable in this environment)
Expected: FAIL — `foodLogs` isn't matched by any rule yet, so `assertSucceeds` on `users/alice/foodLogs/...` fails (falls through to Firestore's default deny).

- [ ] **Step 3: Write the implementation**

In `firestore.rules`, add a `foodLogs` match block alongside the existing `checkIns`/`workoutLogs`/`splitDays` blocks, inside `match /users/{uid} { ... }`:

```
      match /foodLogs/{date} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd firestore-tests && npm test`
Expected: PASS (7 tests — 5 existing + 1 extended assertion set + 1 new denial test)

- [ ] **Step 5: Commit**

```bash
git add firestore.rules firestore-tests/rules.test.js
git commit -m "Extend Firestore security rules to cover foodLogs"
```

---

### Task 8: CalorieGoalScreen (TDEE calculator form)

**Files:**
- Create: `lib/features/profile/calorie_goal_screen.dart`
- Test: `test/features/profile/calorie_goal_screen_test.dart`

**Interfaces:**
- Consumes: `UserRepository` (`watchUser`, `updateCalorieGoal` — Task 5), `calculateTdeeGoal` (Task 3), `TdeeProfile`/`Sex`/`ActivityLevel`/`CalorieGoalDirection` (Task 2).
- Produces: `CalorieGoalScreen({required UserRepository userRepo})`.

- [ ] **Step 1: Write the failing test**

Create `test/features/profile/calorie_goal_screen_test.dart`:

```dart
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/profile/calorie_goal_screen_test.dart`
Expected: FAIL to compile — `package:zeus/features/profile/calorie_goal_screen.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/features/profile/calorie_goal_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../core/firestore/user_repository.dart';
import '../../core/nutrition/tdee_calculator.dart';
import '../../models/app_user.dart';
import '../../models/tdee_profile.dart';

class CalorieGoalScreen extends StatefulWidget {
  const CalorieGoalScreen({super.key, required this.userRepo});

  final UserRepository userRepo;

  @override
  State<CalorieGoalScreen> createState() => _CalorieGoalScreenState();
}

class _CalorieGoalScreenState extends State<CalorieGoalScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  Sex _sex = Sex.male;
  ActivityLevel _activityLevel = ActivityLevel.sedentary;
  CalorieGoalDirection _goal = CalorieGoalDirection.maintain;
  bool _seeded = false;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _seedFrom(TdeeProfile profile) {
    _weightController.text = profile.weightKg.toString();
    _heightController.text = profile.heightCm.toString();
    _ageController.text = profile.age.toString();
    _sex = profile.sex;
    _activityLevel = profile.activityLevel;
    _goal = profile.goal;
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final age = int.tryParse(_ageController.text);
    if (weight == null || height == null || age == null) return;

    final profile = TdeeProfile(
      weightKg: weight,
      heightCm: height,
      age: age,
      sex: _sex,
      activityLevel: _activityLevel,
      goal: _goal,
    );
    final result = calculateTdeeGoal(profile);
    await widget.userRepo.updateCalorieGoal(
      calorieGoal: result.calorieGoal,
      macroGoals: result.macroGoals,
      tdeeProfile: profile,
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  Widget _chipRow<T>(String keyPrefix, List<T> values, T selected, String Function(T) label, void Function(T) onSelect) {
    return Wrap(
      spacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            key: Key('${keyPrefix}_${label(value)}'),
            label: Text(label(value)),
            selected: value == selected,
            onSelected: (_) => setState(() => onSelect(value)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calorie Goal')),
      body: StreamBuilder<AppUser?>(
        stream: widget.userRepo.watchUser(),
        builder: (context, snapshot) {
          final existing = snapshot.data?.tdeeProfile;
          if (!_seeded && existing != null) {
            _seedFrom(existing);
            _seeded = true;
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                TextField(
                  key: const Key('tdee_weight_field'),
                  controller: _weightController,
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  key: const Key('tdee_height_field'),
                  controller: _heightController,
                  decoration: const InputDecoration(labelText: 'Height (cm)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  key: const Key('tdee_age_field'),
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                const Text('Sex'),
                _chipRow('tdee_sex', Sex.values, _sex, (s) => s.value, (s) => _sex = s),
                const SizedBox(height: 8),
                const Text('Activity level'),
                _chipRow('tdee_activity', ActivityLevel.values, _activityLevel, (a) => a.value, (a) => _activityLevel = a),
                const SizedBox(height: 8),
                const Text('Goal'),
                _chipRow('tdee_goal', CalorieGoalDirection.values, _goal, (g) => g.value, (g) => _goal = g),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const Key('tdee_save_button'),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/profile/calorie_goal_screen_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/calorie_goal_screen.dart test/features/profile/calorie_goal_screen_test.dart
git commit -m "Add CalorieGoalScreen (TDEE calculator form)"
```

---

### Task 9: CalorieLogScreen (day view)

**Files:**
- Create: `lib/features/calories/calorie_log_screen.dart`
- Test: `test/features/calories/calorie_log_screen_test.dart`

**Interfaces:**
- Consumes: `FoodLogRepository` (Task 4), `UserRepository.watchUser`/`AppUser.calorieGoal` (Task 2/5), `FoodLog`/`MealType` (Task 1).
- Produces: `CalorieLogScreen({required FoodLogRepository foodLogRepo, required UserRepository userRepo, DateTime? initialDate})`.

- [ ] **Step 1: Write the failing test**

Create `test/features/calories/calorie_log_screen_test.dart`:

```dart
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/calories/calorie_log_screen_test.dart`
Expected: FAIL to compile — `package:zeus/features/calories/calorie_log_screen.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/features/calories/calorie_log_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/firestore/food_log_repository.dart';
import '../../core/firestore/user_repository.dart';
import '../../models/app_user.dart';
import '../../models/food_log.dart';

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const _mealLabels = {
  MealType.breakfast: 'Breakfast',
  MealType.lunch: 'Lunch',
  MealType.dinner: 'Dinner',
  MealType.snacks: 'Snacks',
};

class CalorieLogScreen extends StatefulWidget {
  CalorieLogScreen({
    super.key,
    required this.foodLogRepo,
    required this.userRepo,
    DateTime? initialDate,
  }) : initialDate = initialDate ?? DateTime.now().toUtc();

  final FoodLogRepository foodLogRepo;
  final UserRepository userRepo;
  final DateTime initialDate;

  @override
  State<CalorieLogScreen> createState() => _CalorieLogScreenState();
}

class _CalorieLogScreenState extends State<CalorieLogScreen> {
  late DateTime _date = widget.initialDate;

  void _shiftDay(int delta) {
    setState(() => _date = _date.add(Duration(days: delta)));
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _dateKey(_date);
    return Scaffold(
      appBar: AppBar(
        title: Text(dateKey),
        leading: IconButton(
          key: const Key('calorie_log_prev_day'),
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _shiftDay(-1),
        ),
        actions: [
          IconButton(
            key: const Key('calorie_log_next_day'),
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _shiftDay(1),
          ),
        ],
      ),
      body: StreamBuilder<AppUser?>(
        stream: widget.userRepo.watchUser(),
        builder: (context, userSnapshot) {
          final calorieGoal = userSnapshot.data?.calorieGoal;
          return StreamBuilder<FoodLog>(
            stream: widget.foodLogRepo.watchForDate(dateKey),
            builder: (context, logSnapshot) {
              final log = logSnapshot.data ?? FoodLog.empty(dateKey);

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (calorieGoal == null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: ${log.totalCalories.round()} kcal'),
                        TextButton(
                          key: const Key('calorie_log_set_goal_button'),
                          onPressed: () => context.push('/profile/calorie-goal'),
                          child: const Text('Set your goal'),
                        ),
                      ],
                    )
                  else
                    Text('${log.totalCalories.round()} / $calorieGoal kcal',
                        style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  for (final mealType in MealType.values) ...[
                    Row(
                      children: [
                        Text(_mealLabels[mealType]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${log.meals[mealType]!.fold<double>(0, (sum, e) => sum + e.calories).round()} kcal'),
                        IconButton(
                          key: Key('add_food_${mealType.value}'),
                          icon: const Icon(Icons.add),
                          onPressed: () => context.push('/calories/$dateKey/add/${mealType.value}'),
                        ),
                      ],
                    ),
                    for (final entry in log.meals[mealType]!)
                      ListTile(
                        key: Key('food_entry_${mealType.value}_${entry.name}'),
                        title: Text(entry.name),
                        subtitle: Text('${entry.calories.round()} kcal'),
                      ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/calories/calorie_log_screen_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/calories/calorie_log_screen.dart test/features/calories/calorie_log_screen_test.dart
git commit -m "Add CalorieLogScreen"
```

---

### Task 10: AddFoodScreen (manual + search)

**Files:**
- Create: `lib/features/calories/add_food_screen.dart`
- Test: `test/features/calories/add_food_screen_test.dart`

**Interfaces:**
- Consumes: `FoodLogRepository` (Task 4), `FoodSearchRepository`/`FoodSearchResult`/`FoodSearchException` (Task 6), `FoodEntry`/`FoodEntrySource`/`MealType` (Task 1).
- Produces: `AddFoodScreen({required FoodLogRepository foodLogRepo, required FoodSearchRepository foodSearchRepo, required String date, required MealType mealType})`.

- [ ] **Step 1: Write the failing test**

Create `test/features/calories/add_food_screen_test.dart`:

```dart
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
    await foodLogRepo.saveLog(FoodLog.empty('2026-08-01').withEntryAdded(
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
```

Note: `foodLogRepo.getRecentEntries` looks back from `DateTime.now().toUtc()`, so the fourth test's seeded date (`2026-08-01`) must be within 7 days of the actual current date when the suite runs for the "recently logged" chip to appear — **before running this task**, replace `'2026-08-01'` in that test with a date computed as `DateTime.now().toUtc().subtract(const Duration(days: 1))` formatted `YYYY-MM-DD`, so the fixture is always inside the lookback window regardless of when the suite runs. Use this helper at the top of the test file instead of a literal string:

```dart
String _recentDateKey() {
  final d = DateTime.now().toUtc().subtract(const Duration(days: 1));
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
```

and use `FoodLog.empty(_recentDateKey())` in place of `FoodLog.empty('2026-08-01')` in that test.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/calories/add_food_screen_test.dart`
Expected: FAIL to compile — `package:zeus/features/calories/add_food_screen.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/features/calories/add_food_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../core/firestore/food_log_repository.dart';
import '../../core/nutrition/food_search_repository.dart';
import '../../models/food_entry.dart';
import '../../models/food_log.dart';

enum _AddFoodMode { manual, search }

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({
    super.key,
    required this.foodLogRepo,
    required this.foodSearchRepo,
    required this.date,
    required this.mealType,
  });

  final FoodLogRepository foodLogRepo;
  final FoodSearchRepository foodSearchRepo;
  final String date;
  final MealType mealType;

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  _AddFoodMode _mode = _AddFoodMode.manual;

  final _searchController = TextEditingController();
  List<FoodSearchResult> _searchResults = const [];
  FoodSearchResult? _selectedResult;
  final _quantityController = TextEditingController(text: '100');
  String? _searchError;

  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');

  List<FoodEntry> _recentEntries = const [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await widget.foodLogRepo.getRecentEntries(DateTime.now().toUtc());
    if (mounted) setState(() => _recentEntries = recent);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _searchError = null);
    try {
      final results = await widget.foodSearchRepo.search(query);
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchError = 'Search failed. You can switch to manual entry below.');
    }
  }

  Future<void> _saveEntry(FoodEntry entry) async {
    final log = await widget.foodLogRepo.getForDate(widget.date);
    await widget.foodLogRepo.saveLog(log.withEntryAdded(widget.mealType, entry));
    if (mounted) Navigator.of(context).maybePop();
  }

  void _fillManualFrom(FoodEntry entry) {
    setState(() {
      _mode = _AddFoodMode.manual;
      _nameController.text = entry.name;
      _caloriesController.text = entry.calories.toString();
      _proteinController.text = entry.protein.toString();
      _carbsController.text = entry.carbs.toString();
      _fatController.text = entry.fat.toString();
    });
  }

  Future<void> _saveManual() async {
    final calories = double.tryParse(_caloriesController.text);
    if (_nameController.text.trim().isEmpty || calories == null) return;
    await _saveEntry(FoodEntry(
      name: _nameController.text.trim(),
      calories: calories,
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
      quantity: null,
      unit: null,
      source: FoodEntrySource.manual,
      loggedAt: DateTime.now().toUtc(),
    ));
  }

  Future<void> _saveFromSearch() async {
    final result = _selectedResult;
    final quantity = double.tryParse(_quantityController.text);
    if (result == null || quantity == null) return;
    await _saveEntry(result.scaledEntry(quantity));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Food')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Row(
              children: [
                TextButton(
                  key: const Key('add_food_mode_manual'),
                  onPressed: () => setState(() => _mode = _AddFoodMode.manual),
                  child: const Text('Manual'),
                ),
                TextButton(
                  key: const Key('add_food_mode_search'),
                  onPressed: () => setState(() => _mode = _AddFoodMode.search),
                  child: const Text('Search'),
                ),
              ],
            ),
            if (_recentEntries.isNotEmpty) ...[
              const Text('Recently logged', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in _recentEntries)
                    ActionChip(
                      key: Key('recent_entry_${entry.name}'),
                      label: Text(entry.name),
                      onPressed: () => _fillManualFrom(entry),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (_mode == _AddFoodMode.manual) ...[
              TextField(key: const Key('manual_name_field'), controller: _nameController, decoration: const InputDecoration(labelText: 'Food name')),
              TextField(key: const Key('manual_calories_field'), controller: _caloriesController, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
              TextField(key: const Key('manual_protein_field'), controller: _proteinController, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number),
              TextField(key: const Key('manual_carbs_field'), controller: _carbsController, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number),
              TextField(key: const Key('manual_fat_field'), controller: _fatController, decoration: const InputDecoration(labelText: 'Fat (g)'), keyboardType: TextInputType.number),
              ElevatedButton(key: const Key('manual_save_button'), onPressed: _saveManual, child: const Text('Save')),
            ] else ...[
              TextField(key: const Key('search_query_field'), controller: _searchController, decoration: const InputDecoration(labelText: 'Search food')),
              ElevatedButton(key: const Key('search_run_button'), onPressed: _runSearch, child: const Text('Search')),
              if (_searchError != null) ...[
                Text(_searchError!, key: const Key('search_error_text')),
                TextButton(
                  key: const Key('search_switch_to_manual'),
                  onPressed: () => setState(() => _mode = _AddFoodMode.manual),
                  child: const Text('Switch to manual entry'),
                ),
              ],
              for (final result in _searchResults)
                ListTile(
                  key: Key('search_result_${result.name}'),
                  title: Text(result.name),
                  subtitle: Text('${result.caloriesPer100g.round()} kcal / 100g'),
                  selected: _selectedResult == result,
                  onTap: () => setState(() => _selectedResult = result),
                ),
              if (_selectedResult != null) ...[
                TextField(key: const Key('search_quantity_field'), controller: _quantityController, decoration: const InputDecoration(labelText: 'Quantity (g)'), keyboardType: TextInputType.number),
                ElevatedButton(key: const Key('search_save_button'), onPressed: _saveFromSearch, child: const Text('Save')),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/calories/add_food_screen_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/calories/add_food_screen.dart test/features/calories/add_food_screen_test.dart
git commit -m "Add AddFoodScreen with manual and Open Food Facts search entry"
```

---

### Task 11: Router wiring and navigation entry points

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/profile/profile_screen.dart`
- Modify: `test/features/home/home_screen_test.dart`
- Modify: `test/features/profile/profile_screen_test.dart`

**Interfaces:**
- Consumes: `CalorieLogScreen` (Task 9), `AddFoodScreen` (Task 10), `CalorieGoalScreen` (Task 8), `FoodLogRepository` (Task 4), `FoodSearchRepository` (Task 6).
- Produces: `/calories`, `/calories/:date/add/:mealType`, `/profile/calorie-goal` routes; a calories icon on Home's AppBar; a calorie-goal button on Profile.

- [ ] **Step 1: Write the failing test**

Add to `test/features/home/home_screen_test.dart` (append a new `testWidgets` inside `main()`, reusing the existing `pumpHome` helper and `setUp`):

```dart
  testWidgets('AppBar has a calories nav icon', (tester) async {
    await pumpHome(tester, userRepo: userRepo, splitRepo: splitRepo, checkInRepo: checkInRepo, workoutLogRepo: workoutLogRepo);

    expect(find.byKey(const Key('home_calories_button')), findsOneWidget);
  });
```

Add to `test/features/profile/profile_screen_test.dart` (new `testWidgets`, alongside the existing one):

```dart
  testWidgets('shows a calorie goal button', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true);
    final userRepo = UserRepository(firestore, 'uid-1');
    final authRepo = AuthRepository(auth, (uid) => UserRepository(firestore, uid));
    await userRepo.createInitialUser(name: 'Vani', email: 'vani@example.com');

    await tester.pumpWidget(MaterialApp(home: ProfileScreen(userRepo: userRepo, authRepo: authRepo)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_calorie_goal_button')), findsOneWidget);
    expect(find.text('Set calorie goal'), findsOneWidget);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/home/home_screen_test.dart test/features/profile/profile_screen_test.dart`
Expected: FAIL — neither `home_calories_button` nor `profile_calorie_goal_button` exist yet.

- [ ] **Step 3: Write the implementation**

In `lib/features/home/home_screen.dart`, add one more `IconButton` to the `AppBar.actions` list (after the existing `calendar_month`/`edit_calendar`/`person` icons):

```dart
          IconButton(key: const Key('home_calories_button'), icon: const Icon(Icons.restaurant), onPressed: () => context.push('/calories')),
```

In `lib/features/profile/profile_screen.dart`, replace the file to add the calorie goal button and, if set, the goal display. Add `import 'package:go_router/go_router.dart';` to the imports, then insert into the `Column` (right before the log-out button):

```dart
                if (user.calorieGoal != null) Text('Calorie goal: ${user.calorieGoal} kcal'),
                const SizedBox(height: 8),
                ElevatedButton(
                  key: const Key('profile_calorie_goal_button'),
                  onPressed: () => context.push('/profile/calorie-goal'),
                  child: Text(user.calorieGoal == null ? 'Set calorie goal' : 'Edit calorie goal'),
                ),
                const SizedBox(height: 8),
```

In `lib/core/router/app_router.dart`, add imports:

```dart
import 'package:http/http.dart' as http;
import '../../features/calories/add_food_screen.dart';
import '../../features/calories/calorie_log_screen.dart';
import '../../features/profile/calorie_goal_screen.dart';
import '../firestore/food_log_repository.dart';
import '../nutrition/food_search_repository.dart';
import '../../models/food_log.dart';
```

Add three new `GoRoute`s to the `routes` list (after the existing `/profile` route):

```dart
    GoRoute(
      path: '/calories',
      builder: (context, state) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final firestore = FirebaseFirestore.instance;
        return CalorieLogScreen(
          foodLogRepo: FoodLogRepository(firestore, uid),
          userRepo: UserRepository(firestore, uid),
        );
      },
    ),
    GoRoute(
      path: '/calories/:date/add/:mealType',
      builder: (context, state) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final firestore = FirebaseFirestore.instance;
        return AddFoodScreen(
          foodLogRepo: FoodLogRepository(firestore, uid),
          foodSearchRepo: FoodSearchRepository(http.Client()),
          date: state.pathParameters['date']!,
          mealType: MealType.fromValue(state.pathParameters['mealType']!),
        );
      },
    ),
    GoRoute(
      path: '/profile/calorie-goal',
      builder: (context, state) => CalorieGoalScreen(
        userRepo: UserRepository(FirebaseFirestore.instance, FirebaseAuth.instance.currentUser!.uid),
      ),
    ),
```

- [ ] **Step 4: Run tests to verify they pass, then run the full suite**

Run: `flutter test test/features/home/home_screen_test.dart test/features/profile/profile_screen_test.dart`
Expected: PASS

Run: `flutter test`
Expected: PASS — full suite green, including every Phase 1 test untouched by this plan.

- [ ] **Step 5: Commit**

```bash
git add lib/core/router/app_router.dart lib/features/home/home_screen.dart lib/features/profile/profile_screen.dart test/features/home/home_screen_test.dart test/features/profile/profile_screen_test.dart
git commit -m "Wire calorie tracking into the router and Home/Profile navigation"
```

---

### Task 12: Manual APK verification

No code changes — this is the human-in-the-loop closeout, mirroring Phase 1's Task 16.

- [ ] **Step 1:** Run `flutter build apk --release` and install on a real Android device or emulator.
- [ ] **Step 2:** Deploy the updated `firestore.rules` to the live Firebase project (`firebase deploy --only firestore:rules`) — Phase 1's rules were only ever tested against the emulator before Task 16's deploy; the `foodLogs` rule needs the same deploy step before search/logging will work against the live project.
- [ ] **Step 3:** Walk through, on-device:
  1. Home → tap the calories icon → Calorie Log opens, shows dormant state (no goal set).
  2. Tap "Set your goal" → fill in weight/height/age, pick sex/activity/goal chips → Save → returns to Calorie Log, now shows "`X` / `Y` kcal".
  3. Tap add on Breakfast → Manual tab → enter a food name + calories → Save → entry appears under Breakfast, daily total updates.
  4. Tap add on Lunch → Search tab → search a real food (e.g. "oats") → confirm results appear with per-100g calories → pick one, enter a quantity → Save → entry appears under Lunch with the scaled calorie value.
  5. Search a nonsense query or turn off network mid-search → confirm the inline error + "switch to manual entry" appear, and manual entry still works.
  6. Prev/next day navigation moves correctly and shows that day's previously logged entries.
  7. Profile → confirm "Calorie goal: `X` kcal" is shown and "Edit calorie goal" re-opens the TDEE form pre-filled with the saved values.
  8. Confirm nothing in Phase 1 regressed: check-in streak, split editor, calendar, workout logging all still work exactly as before (calorie tracking touched none of that code).
- [ ] **Step 4:** If all checks pass, Phase 2 is done. Report back before starting Phase 3 (Reminders).
