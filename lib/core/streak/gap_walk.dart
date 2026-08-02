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

/// Normalize a DateTime to UTC midnight (00:00:00.000Z).
DateTime _utcMidnight(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Add one month to a date, clamping the day to the last day of the target month.
/// Prevents overflow: Jan 31 + 1 month = Feb 28/29, not Mar 3.
DateTime _addOneMonth(DateTime d) {
  final year = d.month == 12 ? d.year + 1 : d.year;
  final month = d.month == 12 ? 1 : d.month + 1;
  // Find the last day of the target month by creating the first day of the next month
  // and subtracting 1 day. DateTime.utc(year, month + 1, 0) gives the last day of month.
  final daysInMonth = DateTime.utc(year, month + 1, 0).day;
  final day = d.day > daysInMonth ? daysInMonth : d.day;
  return DateTime.utc(year, month, day);
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
  // Normalize all DateTime inputs to UTC midnight to ensure consistent comparisons,
  // regardless of what time-of-day values callers pass in.
  final normalizedToday = _utcMidnight(today);
  final normalizedFreezesResetDate = _utcMidnight(freezesResetDate);
  final normalizedLastActivityDate = lastActivityDate != null ? _utcMidnight(lastActivityDate) : null;

  // Step 0: monthly freeze reset, before the gap-walk (ordering matters — see spec).
  var effectiveFreezesRemaining = freezesRemaining;
  var effectiveFreezesResetDate = normalizedFreezesResetDate;
  if (!normalizedFreezesResetDate.isAfter(normalizedToday)) {
    effectiveFreezesRemaining = 2;
    effectiveFreezesResetDate = _addOneMonth(normalizedFreezesResetDate);
  }

  if (normalizedLastActivityDate == null) {
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

  var cursor = normalizedLastActivityDate.add(const Duration(days: 1));
  while (cursor.isBefore(normalizedToday)) {
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
