import 'package:flutter/material.dart';
import '../../core/firestore/workout_log_repository.dart';
import '../../models/workout_log.dart';

class SplitDayHistoryScreen extends StatelessWidget {
  const SplitDayHistoryScreen({
    super.key,
    required this.workoutLogRepo,
    required this.splitDayId,
    required this.splitDayLabel,
  });

  final WorkoutLogRepository workoutLogRepo;
  final String splitDayId;
  final String splitDayLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(splitDayLabel)),
      body: StreamBuilder<List<WorkoutLog>>(
        stream: workoutLogRepo.watchCompletedLogsForSplitDay(splitDayId),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? const <WorkoutLog>[];
          return ListView(
            children: [
              for (final log in logs)
                ListTile(
                  title: Text(log.date),
                  subtitle: Text(log.exercises.map((e) => '${e.name}: ${e.actualWeight ?? "-"}kg x ${e.actualReps ?? "-"}').join(', ')),
                ),
            ],
          );
        },
      ),
    );
  }
}
