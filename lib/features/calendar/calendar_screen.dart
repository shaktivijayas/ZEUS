import 'package:flutter/material.dart';
import '../../core/firestore/checkin_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/check_in.dart';

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key, required this.checkInRepo, required this.initialMonth});

  final CheckInRepository checkInRepo;
  final DateTime initialMonth;

  Future<void> _markRestDay(String dateKey) async {
    final firestore = checkInRepo.firestoreInstance;
    final ref = checkInRepo.docRefFor(dateKey);

    await firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (snap.exists) return; // never overwrite an existing doc.

      transaction.set(ref, CheckIn(
        date: dateKey,
        type: CheckInType.restDay,
        timestamp: DateTime.now().toUtc(),
        workoutLogId: null,
      ).toMap());
    });
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

  // Status is carried by icon shape, not hue — see DESIGN.md's No Second
  // Green / One Voice rules, which reserve color for the single accent.
  IconData? get _icon {
    switch (checkIn?.type) {
      case CheckInType.checkedIn:
        return Icons.check;
      case CheckInType.restDay:
        return Icons.bedtime_outlined;
      case CheckInType.freezeUsed:
        return Icons.ac_unit;
      case CheckInType.missed:
        return Icons.close;
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = _icon;

    return InkWell(
      key: Key('calendar_day_${_dateKey(date)}'),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xs),
        alignment: Alignment.center,
        decoration: checkIn != null
            ? BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${date.day}', style: TextStyle(color: colorScheme.onSurface)),
            if (icon != null) Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
