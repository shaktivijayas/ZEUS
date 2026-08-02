import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/models/check_in.dart';

void main() {
  test('CheckIn round-trips and maps type to the spec string values', () {
    final checkIn = CheckIn(
      date: '2026-08-02',
      type: CheckInType.freezeUsed,
      timestamp: DateTime.utc(2026, 8, 2, 9),
      workoutLogId: null,
    );

    final map = checkIn.toMap();
    expect(map['type'], 'freeze_used');

    final restored = CheckIn.fromMap('2026-08-02', map);
    expect(restored.type, CheckInType.freezeUsed);
    expect(restored.workoutLogId, isNull);
  });

  test('all four CheckInType values map to their exact spec strings', () {
    expect(CheckInType.checkedIn.value, 'checked_in');
    expect(CheckInType.restDay.value, 'rest_day');
    expect(CheckInType.freezeUsed.value, 'freeze_used');
    expect(CheckInType.missed.value, 'missed');
  });
}
