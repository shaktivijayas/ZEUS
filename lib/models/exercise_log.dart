enum ExerciseLogStatus {
  done('done'),
  skipped('skipped');

  const ExerciseLogStatus(this.value);

  final String value;

  static ExerciseLogStatus fromValue(String value) {
    return ExerciseLogStatus.values.firstWhere((s) => s.value == value);
  }
}

class ExerciseLog {
  const ExerciseLog({
    required this.name,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.actualSets,
    required this.actualReps,
    required this.actualWeight,
    required this.status,
    required this.notes,
  });

  final String name;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int? actualSets;
  final int? actualReps;
  final double? actualWeight;
  final ExerciseLogStatus status;
  final String notes;

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      name: map['name'] as String,
      targetSets: map['targetSets'] as int,
      targetReps: map['targetReps'] as int,
      targetWeight: (map['targetWeight'] as num).toDouble(),
      actualSets: map['actualSets'] as int?,
      actualReps: map['actualReps'] as int?,
      actualWeight: (map['actualWeight'] as num?)?.toDouble(),
      status: ExerciseLogStatus.fromValue(map['status'] as String),
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetWeight': targetWeight,
        'actualSets': actualSets,
        'actualReps': actualReps,
        'actualWeight': actualWeight,
        'status': status.value,
        'notes': notes,
      };

  ExerciseLog copyWith({
    int? actualSets,
    int? actualReps,
    double? actualWeight,
    ExerciseLogStatus? status,
    String? notes,
  }) {
    return ExerciseLog(
      name: name,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
      actualSets: actualSets ?? this.actualSets,
      actualReps: actualReps ?? this.actualReps,
      actualWeight: actualWeight ?? this.actualWeight,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
