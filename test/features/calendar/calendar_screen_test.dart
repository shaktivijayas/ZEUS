import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/core/firestore/checkin_repository.dart';
import 'package:zeus/features/calendar/calendar_screen.dart';
import 'package:zeus/models/check_in.dart';

void main() {
  testWidgets('tapping a future day marks it as a rest day', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = CheckInRepository(firestore, 'uid-1');

    await tester.pumpWidget(MaterialApp(
      home: CalendarScreen(checkInRepo: repo, initialMonth: DateTime.utc(2026, 8, 1)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calendar_day_2026-08-15')));
    await tester.pumpAndSettle();

    final checkIn = await repo.getCheckIn('2026-08-15');
    expect(checkIn!.type, CheckInType.restDay);
  });

  testWidgets('tapping a day that already has a checked_in doc does not overwrite it', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = CheckInRepository(firestore, 'uid-1');
    await repo.writeCheckIn(CheckIn(date: '2026-08-15', type: CheckInType.checkedIn, timestamp: DateTime.utc(2026, 8, 15), workoutLogId: null));

    await tester.pumpWidget(MaterialApp(
      home: CalendarScreen(checkInRepo: repo, initialMonth: DateTime.utc(2026, 8, 1)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calendar_day_2026-08-15')));
    await tester.pumpAndSettle();

    final checkIn = await repo.getCheckIn('2026-08-15');
    expect(checkIn!.type, CheckInType.checkedIn, reason: 'existing doc must never be overwritten by a calendar tap');
  });
}
