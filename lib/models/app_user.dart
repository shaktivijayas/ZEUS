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
      };

  AppUser copyWith({
    String? name,
    String? email,
    int? currentStreak,
    int? longestStreak,
    int? freezesRemaining,
    DateTime? freezesResetDate,
    bool? onboarded,
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
    );
  }
}
