import 'package:flutter/material.dart';
import '../../core/firestore/checkin_repository.dart';
import '../../models/check_in.dart';

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key, required this.checkInRepo, required this.initialMonth});

  final CheckInRepository checkInRepo;
  final DateTime initialMonth;

  Future<void> _markRestDay(String dateKey) async {
    final existing = await checkInRepo.getCheckIn(dateKey);
    if (existing != null) return; // never overwrite an existing doc.
    await checkInRepo.writeCheckIn(CheckIn(
      date: dateKey,
      type: CheckInType.restDay,
      timestamp: DateTime.now().toUtc(),
      workoutLogId: null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime.utc(initialMonth.year, initialMonth.month + 1, 0).day;

    return Scaffold(
      appBar: AppBar(title: Text('${initialMonth.year}-${initialMonth.month.toString().padLeft(2, '0')}')),
      body: StreamBuilder<List<CheckIn>>(
        stream: checkInRepo.watchCheckInsForMonth(initialMonth.year, initialMonth.month),
        builder: (context, snapshot) {
          final byDate = {for (final c in snapshot.data ?? const <CheckIn>[]) c.date: c};

          return GridView.count(
            crossAxisCount: 7,
            children: [
              for (var day = 1; day <= daysInMonth; day++)
                _DayCell(
                  date: DateTime.utc(initialMonth.year, initialMonth.month, day),
                  checkIn: byDate[_dateKey(DateTime.utc(initialMonth.year, initialMonth.month, day))],
                  onTap: () => _markRestDay(_dateKey(DateTime.utc(initialMonth.year, initialMonth.month, day))),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.date, required this.checkIn, required this.onTap});

  final DateTime date;
  final CheckIn? checkIn;
  final VoidCallback onTap;

  Color? get _color {
    switch (checkIn?.type) {
      case CheckInType.checkedIn:
        return Colors.green.shade300;
      case CheckInType.restDay:
        return Colors.blue.shade100;
      case CheckInType.freezeUsed:
        return Colors.orange.shade200;
      case CheckInType.missed:
        return Colors.red.shade200;
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('calendar_day_${_dateKey(date)}'),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        color: _color,
        alignment: Alignment.center,
        child: Text('${date.day}'),
      ),
    );
  }
}
