import 'exercise_target.dart';

class SplitDay {
  const SplitDay({
    required this.id,
    required this.label,
    required this.order,
    required this.exercises,
  });

  final String id;
  final String label;
  final int order;
  final List<ExerciseTarget> exercises;

  factory SplitDay.fromMap(String id, Map<String, dynamic> map) {
    final rawExercises = map['exercises'] as List<dynamic>? ?? [];
    return SplitDay(
      id: id,
      label: map['label'] as String,
      order: map['order'] as int,
      exercises: rawExercises
          .map((e) => ExerciseTarget.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'order': order,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };

  SplitDay copyWith({String? label, int? order, List<ExerciseTarget>? exercises}) {
    return SplitDay(
      id: id,
      label: label ?? this.label,
      order: order ?? this.order,
      exercises: exercises ?? this.exercises,
    );
  }
}
