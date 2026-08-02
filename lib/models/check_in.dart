enum CheckInType {
  checkedIn('checked_in'),
  restDay('rest_day'),
  freezeUsed('freeze_used'),
  missed('missed');

  const CheckInType(this.value);

  final String value;

  static CheckInType fromValue(String value) {
    return CheckInType.values.firstWhere((t) => t.value == value);
  }
}

class CheckIn {
  const CheckIn({
    required this.date,
    required this.type,
    required this.timestamp,
    required this.workoutLogId,
  });

  /// "YYYY-MM-DD" — also the Firestore doc ID.
  final String date;
  final CheckInType type;
  final DateTime timestamp;
  final String? workoutLogId;

  factory CheckIn.fromMap(String date, Map<String, dynamic> map) {
    return CheckIn(
      date: date,
      type: CheckInType.fromValue(map['type'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String),
      workoutLogId: map['workoutLogId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.value,
        'timestamp': timestamp.toIso8601String(),
        'workoutLogId': workoutLogId,
      };
}
