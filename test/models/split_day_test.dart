import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/models/exercise_target.dart';
import 'package:zeus/models/split_day.dart';

void main() {
  test('SplitDay round-trips with nested exercises', () {
    final day = SplitDay(
      id: 'monday',
      label: 'Chest & Shoulders',
      order: 0,
      exercises: const [
        ExerciseTarget(name: 'Bench Press', targetSets: 4, targetReps: 8, targetWeight: 60, order: 0),
        ExerciseTarget(name: 'Overhead Press', targetSets: 3, targetReps: 10, targetWeight: 30, order: 1),
      ],
    );

    final restored = SplitDay.fromMap(day.id, day.toMap());

    expect(restored.label, 'Chest & Shoulders');
    expect(restored.exercises, hasLength(2));
    expect(restored.exercises[1].name, 'Overhead Press');
    expect(restored.exercises[1].targetWeight, 30);
  });
}
