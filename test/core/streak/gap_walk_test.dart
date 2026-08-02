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
  });
}
