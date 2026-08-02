import 'exercise_log.dart';

enum WorkoutLogStatus {
  draft('draft'),
  completed('completed');

  const WorkoutLogStatus(this.value);

  final String value;

  static WorkoutLogStatus fromValue(String value) {
    return WorkoutLogStatus.values.firstWhere((s) => s.value == value);
  }
}

class WorkoutLog {
  const WorkoutLog({
    required this.id,
    required this.date,
    required this.splitDayId,
    required this.status,
    required this.exercises,
    required this.completedAt,
  });

  final String id;
  final String date;
  final String splitDayId;
  final WorkoutLogStatus status;
  final List<ExerciseLog> exercises;
  final DateTime? completedAt;

  factory WorkoutLog.fromMap(String id, Map<String, dynamic> map) {
    final rawExercises = map['exercises'] as List<dynamic>? ?? [];
    return WorkoutLog(
      id: id,
      date: map['date'] as String,
      splitDayId: map['splitDayId'] as String,
      status: WorkoutLogStatus.fromValue(map['status'] as String),
      exercises: rawExercises
          .map((e) => ExerciseLog.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      completedAt: map['completedAt'] == null ? null : DateTime.parse(map['completedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date,
        'splitDayId': splitDayId,
        'status': status.value,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'completedAt': completedAt?.toIso8601String(),
      };

  WorkoutLog copyWith({WorkoutLogStatus? status, List<ExerciseLog>? exercises, DateTime? completedAt}) {
    return WorkoutLog(
      id: id,
      date: date,
      splitDayId: splitDayId,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
