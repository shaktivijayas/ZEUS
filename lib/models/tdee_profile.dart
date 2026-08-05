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
