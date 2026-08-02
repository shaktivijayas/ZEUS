import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/firestore/split_repository.dart';
import 'package:zeus/models/exercise_target.dart';
import 'package:zeus/models/split_day.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SplitRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = SplitRepository(firestore, 'uid-1');
  });

  test('saveSplitDay then watchSplitDays emits it ordered by `order`', () async {
    await repo.saveSplitDay(const SplitDay(
      id: 'wednesday',
      label: 'Legs',
      order: 2,
      exercises: [],
    ));
    await repo.saveSplitDay(const SplitDay(
      id: 'monday',
      label: 'Chest & Shoulders',
      order: 0,
      exercises: [ExerciseTarget(name: 'Bench Press', targetSets: 4, targetReps: 8, targetWeight: 60, order: 0)],
    ));

    final days = await repo.watchSplitDays().first;

    expect(days, hasLength(2));
    expect(days[0].id, 'monday');
    expect(days[1].id, 'wednesday');
  });

  test('deleteSplitDay removes the day', () async {
    await repo.saveSplitDay(const SplitDay(id: 'monday', label: 'Chest', order: 0, exercises: []));
    await repo.deleteSplitDay('monday');

    final days = await repo.watchSplitDays().first;
    expect(days, isEmpty);
  });
}
