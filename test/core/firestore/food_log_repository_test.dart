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
    // Verify entries are returned newest-first by loggedAt timestamp
    expect(recent.map((e) => e.name).toList(), ['C', 'B']);
  });

  test('watchLogsForRange only includes logs with a doc ID inside the date range', () async {
    await repo.saveLog(FoodLog.empty('2026-07-31').withEntryAdded(MealType.dinner, _entry('Outside before', 100, DateTime.utc(2026, 7, 31, 19))));
    await repo.saveLog(FoodLog.empty('2026-08-05').withEntryAdded(MealType.lunch, _entry('Dal', 350, DateTime.utc(2026, 8, 5, 13))));
    await repo.saveLog(FoodLog.empty('2026-09-01').withEntryAdded(MealType.breakfast, _entry('Outside after', 100, DateTime.utc(2026, 9, 1, 8))));

    final results = await repo.watchLogsForRange('2026-08-01', '2026-08-31').first;

    expect(results.map((l) => l.date).toList(), ['2026-08-05']);
  });
}
