import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/firestore/checkin_repository.dart';
import 'package:zeus/models/check_in.dart';

DateTime d(int y, int m, int day, [int hour = 0]) => DateTime.utc(y, m, day, hour);

void main() {
  late FakeFirebaseFirestore firestore;
  late CheckInRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = CheckInRepository(firestore, 'uid-1');
  });

  test('writeCheckIn uses the date string as the doc ID (idempotent overwrite)', () async {
    await repo.writeCheckIn(CheckIn(date: '2026-08-02', type: CheckInType.checkedIn, timestamp: d(2026, 8, 2), workoutLogId: null));
    await repo.writeCheckIn(CheckIn(date: '2026-08-02', type: CheckInType.checkedIn, timestamp: d(2026, 8, 2, 1), workoutLogId: 'log-1'));

    final checkIn = await repo.getCheckIn('2026-08-02');
    expect(checkIn!.workoutLogId, 'log-1', reason: 'second write overwrote the same doc, not a duplicate');
  });

  test('getLastActivityDate returns the most recent checkIns doc date', () async {
    await repo.writeCheckIn(CheckIn(date: '2026-07-30', type: CheckInType.checkedIn, timestamp: d(2026, 7, 30), workoutLogId: null));
    await repo.writeCheckIn(CheckIn(date: '2026-08-01', type: CheckInType.checkedIn, timestamp: d(2026, 8, 1), workoutLogId: null));

    final last = await repo.getLastActivityDate();
    expect(last, d(2026, 8, 1));
  });

  test('getLastActivityDate returns null when no checkIns exist', () async {
    final last = await repo.getLastActivityDate();
    expect(last, isNull);
  });

  test('getCheckInsInRange returns only docs strictly between start and end, keyed by date', () async {
    await repo.writeCheckIn(CheckIn(date: '2026-08-01', type: CheckInType.checkedIn, timestamp: d(2026, 8, 1), workoutLogId: null));
    await repo.writeCheckIn(CheckIn(date: '2026-08-02', type: CheckInType.restDay, timestamp: d(2026, 8, 2), workoutLogId: null));
    await repo.writeCheckIn(CheckIn(date: '2026-08-05', type: CheckInType.checkedIn, timestamp: d(2026, 8, 5), workoutLogId: null));

    final range = await repo.getCheckInsInRange(d(2026, 8, 1), d(2026, 8, 5));

    expect(range.keys, {'2026-08-02'});
  });

  test('writeCheckIns batch-writes multiple docs', () async {
    await repo.writeCheckIns([
      CheckIn(date: '2026-08-02', type: CheckInType.freezeUsed, timestamp: d(2026, 8, 2), workoutLogId: null),
      CheckIn(date: '2026-08-03', type: CheckInType.missed, timestamp: d(2026, 8, 3), workoutLogId: null),
    ]);

    expect((await repo.getCheckIn('2026-08-02'))!.type, CheckInType.freezeUsed);
    expect((await repo.getCheckIn('2026-08-03'))!.type, CheckInType.missed);
  });
}
