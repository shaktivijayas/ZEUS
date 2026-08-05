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
