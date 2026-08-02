import '../../models/check_in.dart';

class GapWalkResult {
  const GapWalkResult({
    required this.writes,
    required this.newStreak,
    required this.newFreezesRemaining,
    required this.newFreezesResetDate,
  });

  final List<CheckIn> writes;
  final int newStreak;
  final int newFreezesRemaining;
  final DateTime newFreezesResetDate;
}

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _addOneMonth(DateTime d) {
  final year = d.month == 12 ? d.year + 1 : d.year;
  final month = d.month == 12 ? 1 : d.month + 1;
  return DateTime.utc(year, month, d.day);
}

/// Pure function implementing the spec's "Multi-day gap algorithm (runs on
/// app open)": monthly freeze reset first, then the gap-walk itself.
GapWalkResult runGapWalk({
  required DateTime? lastActivityDate,
  required DateTime today,
  required int currentStreak,
  required int freezesRemaining,
  required DateTime freezesResetDate,
  required Map<String, CheckIn> existingCheckIns,
}) {
  // Step 0: monthly freeze reset, before the gap-walk (ordering matters — see spec).
  var effectiveFreezesRemaining = freezesRemaining;
  var effectiveFreezesResetDate = freezesResetDate;
  if (!freezesResetDate.isAfter(today)) {
    effectiveFreezesRemaining = 2;
    effectiveFreezesResetDate = _addOneMonth(freezesResetDate);
  }

  if (lastActivityDate == null) {
    return GapWalkResult(
      writes: const [],
      newStreak: currentStreak,
      newFreezesRemaining: effectiveFreezesRemaining,
      newFreezesResetDate: effectiveFreezesResetDate,
    );
  }

  final writes = <CheckIn>[];
  var streak = currentStreak;
  var freezes = effectiveFreezesRemaining;
  var streakBroken = false;

  var cursor = lastActivityDate.add(const Duration(days: 1));
  while (cursor.isBefore(today)) {
    final key = _dateKey(cursor);
    final existing = existingCheckIns[key];

    if (existing == null) {
      if (!streakBroken && freezes > 0) {
        freezes -= 1;
        writes.add(CheckIn(date: key, type: CheckInType.freezeUsed, timestamp: cursor, workoutLogId: null));
      } else {
        streakBroken = true;
        streak = 0;
        writes.add(CheckIn(date: key, type: CheckInType.missed, timestamp: cursor, workoutLogId: null));
      }
    }
    // else: a doc already exists for this date (e.g. a pre-marked rest day) —
    // skip it entirely, never touch it, never consume a freeze.

    cursor = cursor.add(const Duration(days: 1));
  }

  return GapWalkResult(
    writes: writes,
    newStreak: streak,
    newFreezesRemaining: freezes,
    newFreezesResetDate: effectiveFreezesResetDate,
  );
}
