class ExerciseTarget {
  const ExerciseTarget({
    required this.name,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.order,
  });

  final String name;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int order;

  factory ExerciseTarget.fromMap(Map<String, dynamic> map) {
    return ExerciseTarget(
      name: map['name'] as String,
      targetSets: map['targetSets'] as int,
      targetReps: map['targetReps'] as int,
      targetWeight: (map['targetWeight'] as num).toDouble(),
      order: map['order'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetWeight': targetWeight,
        'order': order,
      };
}
