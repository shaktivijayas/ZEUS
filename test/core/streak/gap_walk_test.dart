import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/streak/gap_walk.dart';
import 'package:zeus/models/check_in.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  group('runGapWalk', () {
    test('no gap: lastActivityDate is yesterday, nothing to backfill', () {
      final result = runGapWalk(
        lastActivityDate: d(2026, 8, 1),
        today: d(2026, 8, 2),
        currentStreak: 5,
        freezesRemaining: 2,
        freezesResetDate: d(2026, 9, 1),
        existingCheckIns: {},
      );

      expect(result.writes, isEmpty);
      expect(result.newStreak, 5);
      expect(result.newFreezesRemaining, 2);
    });

    test('first-ever open: lastActivityDate is null, nothing to walk', () {
      final result = runGapWalk(
        lastActivityDate: null,
        today: d(2026, 8, 2),
        currentStreak: 0,
        freezesRemaining: 2,
        freezesResetDate: d(2026, 9, 1),
        existingCheckIns: {},
      );

      expect(result.writes, isEmpty);
      expect(result.newStreak, 0);
      expect(result.newFreezesRemaining, 2);
    });

    test('single missed day with freezes available consumes one freeze, streak survives', () {
      final result = runGapWalk(
        lastActivityDate: d(2026, 8, 1),
        today: d(2026, 8, 3),
        currentStreak: 5,
        freezesRemaining: 2,
        freezesResetDate: d(2026, 9, 1),
        existingCheckIns: {},
      );

      expect(result.writes, hasLength(1));
      expect(result.writes.single.date, '2026-08-02');
      expect(result.writes.single.type, CheckInType.freezeUsed);
      expect(result.newFreezesRemaining, 1);
      expect(result.newStreak, 5, reason: 'freeze bridges the gap, streak untouched');
    });

    test('rest day pre-marked in the gap is skipped, never overwritten, no freeze consumed', () {
      final restDay = CheckIn(
        date: '2026-08-02',
        type: CheckInType.restDay,
        timestamp: d(2026, 7, 20),
        workoutLogId: null,
      );

      final result = runGapWalk(
        lastActivityDate: d(2026, 8, 1),
        today: d(2026, 8, 3),
        currentStreak: 5,
        freezesRemaining: 2,
        freezesResetDate: d(2026, 9, 1),
        existingCheckIns: {'2026-08-02': restDay},
      );

      expect(result.writes, isEmpty, reason: 'pre-existing doc is left untouched, not rewritten');
      expect(result.newFreezesRemaining, 2);
      expect(result.newStreak, 5);
    });

    test('gap exceeds freeze budget: streak resets to 0 and all remaining days in the gap are backfilled missed', () {
      final result = runGapWalk(
        lastActivityDate: d(2026, 8, 1),
        today: d(2026, 8, 6),
        currentStreak: 5,
        freezesRemaining: 1,
        freezesResetDate: d(2026, 9, 1),
        existingCheckIns: {},
      );

      // Gap days: Aug 2, 3, 4, 5. First consumes the one freeze; the other three are missed.
      expect(result.writes, hasLength(4));
      expect(result.writes[0].date, '2026-08-02');
      expect(result.writes[0].type, CheckInType.freezeUsed);
      expect(result.writes[1].date, '2026-08-03');
      expect(result.writes[1].type, CheckInType.missed);
      expect(result.writes[2].date, '2026-08-04');
      expect(result.writes[2].type, CheckInType.missed);
      expect(result.writes[3].date, '2026-08-05');
      expect(result.writes[3].type, CheckInType.missed);
      expect(result.newStreak, 0);
      expect(result.newFreezesRemaining, 0);
    });

    test('rest days bridge a gap that would otherwise exceed the freeze budget', () {
      final restDay = CheckIn(
        date: '2026-08-03',
        type: CheckInType.restDay,
        timestamp: d(2026, 7, 20),
        workoutLogId: null,
      );

      final result = runGapWalk(
        lastActivityDate: d(2026, 8, 1),
        today: d(2026, 8, 4),
        currentStreak: 5,
        freezesRemaining: 1,
        freezesResetDate: d(2026, 9, 1),
        existingCheckIns: {'2026-08-03': restDay},
      );

      // Gap days: Aug 2 (missing, consumes freeze), Aug 3 (pre-existing rest day, skipped).
      expect(result.writes, hasLength(1));
      expect(result.writes.single.date, '2026-08-02');
      expect(result.writes.single.type, CheckInType.freezeUsed);
      expect(result.newStreak, 5);
      expect(result.newFreezesRemaining, 0);
    });

    test('monthly freeze reset happens before the gap-walk, ordering matters', () {
      // freezesResetDate has already passed relative to today; freezesRemaining is
      // stale at 0. If the reset didn't run first, the single gap day below would
      // wrongly be written `missed` and zero the streak — instead it must be
      // bridged by the freshly-reset freeze budget.
      final result = runGapWalk(
        lastActivityDate: d(2026, 8, 1),
        today: d(2026, 8, 3),
        currentStreak: 5,
        freezesRemaining: 0,
        freezesResetDate: d(2026, 8, 2),
        existingCheckIns: {},
      );

      expect(result.newFreezesResetDate, DateTime.utc(2026, 9, 2));
      expect(result.writes, hasLength(1));
      expect(result.writes.single.type, CheckInType.freezeUsed);
      expect(result.newFreezesRemaining, 1, reason: 'reset to 2, then one consumed by the gap day');
      expect(result.newStreak, 5);
    });

    test('freezesResetDate not yet passed: no reset, current budget applies unchanged', () {
      final result = runGapWalk(
        lastActivityDate: d(2026, 8, 1),
        today: d(2026, 8, 2),
        currentStreak: 5,
        freezesRemaining: 0,
        freezesResetDate: d(2026, 9, 1),
        existingCheckIns: {},
      );

      expect(result.newFreezesResetDate, d(2026, 9, 1));
      expect(result.newFreezesRemaining, 0);
    });

    test('month-end overflow: freezesResetDate on Jan 31 + 1 month lands on Feb 28, not Mar 3', () {
      // This tests the _addOneMonth fix: Jan 31 + 1 month should clamp to Feb 28,
      // not overflow to Mar 3. We pass freezesResetDate of Jan 31, 2026 (which has
      // already passed relative to today = Feb 2), triggering a reset.
      // In 2026, Feb has 28 days (not a leap year), so the reset date should be Feb 28, 2026.
      // Gap days: Feb 1 (missing, consumes 1 freeze).
      final result = runGapWalk(
        lastActivityDate: d(2026, 1, 31),
        today: d(2026, 2, 2),
        currentStreak: 5,
        freezesRemaining: 0,
        freezesResetDate: d(2026, 1, 31),
        existingCheckIns: {},
      );

      // The reset should fire (Jan 31 is not after Feb 2), resetting to 2 freezes,
      // then the gap day (Feb 1) consumes 1 freeze, leaving 1.
      expect(result.newFreezesResetDate, d(2026, 2, 28));
      expect(result.newFreezesRemaining, 1, reason: 'reset to 2, then 1 consumed by gap day');
      expect(result.writes, hasLength(1));
      expect(result.writes.single.type, CheckInType.freezeUsed);
    });

    test('midnight-UTC normalization: DateTimes with nonzero time-of-day normalize to midnight', () {
      // This tests that the function normalizes all DateTime inputs to UTC midnight,
      // so callers passing time-of-day components don't get unexpected behavior.
      // We compare a call with midnight values vs. nonzero time-of-day values.
      final resultMidnight = runGapWalk(
        lastActivityDate: d(2026, 8, 1),
        today: d(2026, 8, 3),
        currentStreak: 5,
        freezesRemaining: 2,
        freezesResetDate: d(2026, 9, 1),
        existingCheckIns: {},
      );

      final resultWithTime = runGapWalk(
        // Same dates, but with nonzero time components (15:30:45 UTC).
        lastActivityDate: DateTime.utc(2026, 8, 1, 15, 30, 45),
        today: DateTime.utc(2026, 8, 3, 15, 30, 45),
        currentStreak: 5,
        freezesRemaining: 2,
        freezesResetDate: DateTime.utc(2026, 9, 1, 15, 30, 45),
        existingCheckIns: {},
      );

      // Both should produce identical results because the function normalizes to midnight.
      expect(resultWithTime.writes, hasLength(resultMidnight.writes.length));
      expect(resultWithTime.newStreak, resultMidnight.newStreak);
      expect(resultWithTime.newFreezesRemaining, resultMidnight.newFreezesRemaining);
      expect(resultWithTime.newFreezesResetDate, resultMidnight.newFreezesResetDate);
    });
  });
}
